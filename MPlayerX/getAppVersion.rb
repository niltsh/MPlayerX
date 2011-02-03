require 'osx/cocoa'
include OSX
OSX.require_framework 'ScriptingBridge'

info = NSMutableDictionary.alloc.initWithContentsOfFile_(ARGV[0] + "/Contents/Info.plist")

if info != nil then
	## could read the plist file
	VER = info.objectForKey_("CFBundleShortVersionString")
	
	$stdout << VER
	
	ENV['MPXVER'] = VER
end