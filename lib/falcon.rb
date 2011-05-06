module Falcon
  autoload :Profile, 'falcon/profile'
  autoload :ActiveRecord, 'falcon/active_record'
  autoload :Encoder, 'falcon/encoder'
  
  CONTENT_TYPES = [
    'application/x-mp4',
    'video/mpeg',
    'video/quicktime',
    'video/x-la-asf',
    'video/x-ms-asf',
    'video/x-msvideo',
    'video/x-sgi-movie',
    'video/x-flv',
    'flv-application/octet-stream',
    'application/octet-stream',
    'video/3gpp',
    'video/3gpp2',
    'video/3gpp-tt',
    'video/BMPEG',
    'video/BT656',
    'video/CelB',
    'video/DV',
    'video/H261',
    'video/H263',
    'video/H263-1998',
    'video/H263-2000',
    'video/H264',
    'video/JPEG',
    'video/MJ2',
    'video/MP1S',
    'video/MP2P',
    'video/MP2T',
    'video/mp4',
    'video/MP4V-ES',
    'video/MPV',
    'video/mpeg4',
    'video/mpeg4-generic',
    'video/nv',
    'video/parityfec',
    'video/pointer',
    'video/raw',
    'video/rtx',
    'video/x-matroska',
    'video/x-ms-wmv',
    'video/divxplus',
    'video/avi',
    'video/divx',
    'video/vnd.objectvideo' ]
  
  def self.table_name_prefix
    'falcon_'
  end
  
  def self.redis
    Falcon::Redis.instance
  end
end
