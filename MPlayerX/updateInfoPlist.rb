require 'osx/cocoa'
include OSX
OSX.require_framework 'ScriptingBridge'

info = NSMutableDictionary.alloc.initWithContentsOfFile_(ARGV[0])

if info != nil then
	## could read the plist file
	currentVersion = %x[bash version.sh]
	
	if currentVersion == "unknown" then
		puts "version is invalid!"
	else
		puts "version is valid:" + currentVersion
		
		currentVersion = currentVersion.chomp
		
		info.setValue_forKey_(currentVersion, "CFBundleVersion")
		
		commitHash = %x[git rev-list --max-count=1 HEAD]
		
		commitHash = commitHash.chomp
		
		info.setValue_forKey_(commitHash, "MPXCommitHash")
		
		info.writeToFile_atomically_(ARGV[0], 0)
	end
end