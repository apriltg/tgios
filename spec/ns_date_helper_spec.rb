describe 'Tgios::NSDateHelper' do
  it 'should return NSDate from a normal api time string' do
    date = NSDate.dateWithTimeIntervalSince1970(33)
    date.compare(Tgios::NSDateHelper.to_nsdate('1970-01-01T00:00:33Z')).should == NSOrderedSame
  end

  it 'should return NSDate from a clear time string' do
    date = NSDate.dateWithTimeIntervalSince1970((((1*365+32)*24+23)*60+55)*60+59)
    date.compare(Tgios::NSDateHelper.to_nsdate('1971-02-02 23:55:59')).should == NSOrderedSame
  end
end