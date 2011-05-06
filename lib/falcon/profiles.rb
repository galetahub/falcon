Falcon::Profile.new("web_mp4", {:player => 'flash', :container => "mp4", :extname => 'mp4',
  :width => 480, :height => 320, :video_codec => "libx264",
  :video_bitrate => 500, :fps => 29.97, :audio_codec => "libfaac",
  :command => "-vpre medium",
  :audio_bitrate => 128, :audio_sample_rate => 48000})

Falcon::Profile.new("web_ogg", {:player => 'html5', :container => "ogg", :extname => 'ogv',
  :width => 480, :height => 320, :video_codec => "libtheora",
  :video_bitrate => 500, :fps => 29.97, :audio_codec => "libvorbis",
  :audio_bitrate => 128, :audio_sample_rate => 48000})
