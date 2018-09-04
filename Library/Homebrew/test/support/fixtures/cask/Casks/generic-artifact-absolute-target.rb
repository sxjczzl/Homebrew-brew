cask 'generic-artifact-absolute-target' do
  artifact 'Caffeine.app', target: "#{Cask::Config.global.appdir}/Caffeine.app"
end
