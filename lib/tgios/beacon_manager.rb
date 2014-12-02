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
    attr_accessor :rssi, :tolerance, :current_beacon, :background

    BeaconFoundKey = 'Tgios::BeaconManager::BeaconFound'
    EnterRegionKey = 'Tgios::BeaconManager::EnterRegion'
    ExitRegionKey = 'Tgios::BeaconManager::ExitRegion'

    def self.default=(val)
      @default = val
    end

    def self.default
      @default
    end

    def initialize(uuid, rssi=-70, background=false, tolerance=5)
      @events = {}
      @previous_beacons = []
      @background = background
      @tolerance = (tolerance || 5)

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
        manager.startRangingBeaconsInRegion(region)
      end
    end

    def locationManager(manager, didEnterRegion: region)
      NSLog 'didEnterRegion'
      if region.isKindOfClass(CLBeaconRegion)
        manager.startRangingBeaconsInRegion(region)
      end
    end

    def locationManager(manager, didExitRegion: region)
      NSLog 'didExitRegion'
      if region.isKindOfClass(CLBeaconRegion)
        manager.stopRangingBeaconsInRegion(region)
        if has_event(:exit_region)
          @events[:exit_region].call(region)
        end
      end
    end

    def locationManager(manager, didRangeBeacons: beacons, inRegion: region)

      beacons = beacons.sort_by{|b| b.rssi}.reverse
      known_beacons = beacons.select{|b| b.proximity != CLProximityUnknown}
      unknown_beacons = beacons - known_beacons
      beacon = nil
      beacon = known_beacons.first if known_beacons.first.rssi >= @rssi if known_beacons.present?
      

      push_beacon(beacon) unless beacon.nil?

      if has_event(:beacons_found)
        @events[:beacons_found].call(known_beacons.select{|b| b.rssi >= @rssi}, beacons, @current_beacon)
      end

      if has_event(:beacon_found)
        @events[:beacon_found].call(@current_beacon)
      end

      BeaconFoundKey.post_notification(self, {region: region, beacon: @current_beacon})
    end

    def location_manager
      @location_manager ||=
          begin
            manager = CLLocationManager.alloc.init
            manager.delegate = self
            request_authorization(manager)
            manager
          end
    end

    def request_authorization(manager)
      if manager.respond_to?(:requestAlwaysAuthorization)
        status = CLLocationManager.authorizationStatus
        if status == KCLAuthorizationStatusAuthorizedWhenInUse || status == KCLAuthorizationStatusDenied
          title = (status == kCLAuthorizationStatusDenied) ? "Location services are off" : "Background location is not enabled"
          message = "To use background location you must turn on 'Always' in the Location Services Settings"

          UIAlertView.alert(title, message: message)
        else
          manager.requestAlwaysAuthorization
        end
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
      stop_monitor unless @background
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
      @previous_beacons.delete_at(0) if @previous_beacons.length > @tolerance
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
