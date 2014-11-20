module Tgios
  class FakeBeacon
    attr_accessor :proximityUUID, :major, :minor

    def initialize(attributes)
      attributes.each do |k, v|
        k = :proximityUUID if k.to_s == 'uuid'
        instance_variable_set("@#{k}", v)
      end
    end
  end

  class BeaconManager < BindingBase
    attr_accessor :rssi

    def self.default=(val)
      @default = val
    end

    def self.default
      @default
    end

    def initialize(uuid, rssi=-70)
      @events = {}
      @previous_beacons = []

      @uuid = NSUUID.alloc.initWithUUIDString(uuid)
      @rssi = rssi

      @region = CLBeaconRegion.alloc.initWithProximityUUID(@uuid, identifier: uuid.split('-').first)
      @region.notifyOnEntry = true
      @region.notifyOnExit = true
      @region.notifyEntryStateOnDisplay = true

      start_monitor

      UIApplicationWillEnterForegroundNotification.add_observer(self, 'on_enter_foreground:')
      UIApplicationDidEnterBackgroundNotification.add_observer(self, 'on_enter_background:')
    end

    def on(event_key,&block)
      @events[event_key] = block.weak!
      self
    end

    def locationManager(manager, didDetermineState: state, forRegion: region)
      NSLog "didDetermineState #{state}"
      if state == CLRegionStateInside
        location_manager.startRangingBeaconsInRegion(region)
      end
    end

    def locationManager(manager, didEnterRegion: region)
      NSLog 'didEnterRegion'
      if region.isKindOfClass(CLBeaconRegion)
        location_manager.startRangingBeaconsInRegion(region)
      end
    end

    def locationManager(manager, didExitRegion: region)
      NSLog 'didExitRegion'
      if region.isKindOfClass(CLBeaconRegion)
        location_manager.stopRangingBeaconsInRegion(region)
      end
    end

    def locationManager(manager, didRangeBeacons: beacons, inRegion: region)
      if has_event(:beacons_found)
        @events[:beacons_found].call(beacons.select{|b| b.proximity != CLProximityUnknown && b.rssi >= @rssi})
      end
      if has_event(:beacon_found)
        known_beacons = beacons.select{|b| b.proximity != CLProximityUnknown}.sort_by{|b| b.rssi}
        if known_beacons.present?
          beacon = known_beacons.last if known_beacons.last.rssi >= @rssi
          beacon ||= known_beacons.last if known_beacons.length == 1 && known_beacons.last.rssi >= @rssi - 1
        end

        push_beacon(beacon)
        @events[:beacon_found].call(@current_beacon)
      end
    end

    def location_manager
      @location_manager ||=
          begin
            manager = CLLocationManager.alloc.init
            manager.delegate = self
            manager.requestAlwaysAuthorization if manager.respond_to?(:requestAlwaysAuthorization)
            manager
          end
    end

    def start_monitor
      location_manager.startMonitoringForRegion(@region)
      location_manager.requestStateForRegion(@region)
    end

    def stop_monitor
      location_manager.stopRangingBeaconsInRegion(@region)
      location_manager.stopMonitoringForRegion(@region)
    end

    def on_enter_foreground(noti)
      NSLog 'on_enter_foreground'
      self.performSelector('start_monitor', withObject: nil, afterDelay:1)
    end

    def on_enter_background(noti)
      NSLog 'on_enter_background'
      stop_monitor
    end

    def has_event(event)
      @events.has_key?(event)
    end

    def push_beacon(beacon)
      if beacon_eqs(beacon, @current_beacon)
        @current_beacon = beacon
      else
        if @previous_beacons.find { |b| !beacon_eqs(beacon, b) }.blank?
          @current_beacon = beacon
        else
          @current_beacon = nil if @previous_beacons.find{ |b| beacon_eqs(@current_beacon, b)}.blank?
        end
      end
      @previous_beacons << beacon
      @previous_beacons.delete_at(0) if @previous_beacons.length > 3
    end

    def beacon_eqs(beacon1, beacon2)
      self.class.beacon_eqs(beacon1, beacon2)
    end

    def self.beacon_eqs(beacon1, beacon2)
      return beacon1 == beacon2 if beacon1.nil? || beacon2.nil?
      beacon1.minor == beacon2.minor && beacon1.major == beacon2.major && beacon1.proximityUUID == beacon2.proximityUUID
    end

    def new_fake_beacon(options)
      FakeBeacon.new({uuid: @uuid}.merge(options))
    end

    def self.supported
      CLLocationManager.isRangingAvailable
    end

    def onPrepareForRelease
      UIApplicationWillEnterForegroundNotification.remove_observer(self)
      UIApplicationDidEnterBackgroundNotification.remove_observer(self)
      stop_monitor
      @location_manager = nil
      @events = nil
      @current_beacon = nil
      @previous_beacons = nil
    end

    def dealloc
      onPrepareForRelease
      super
    end
  end
end