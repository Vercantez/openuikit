Pod::Spec.new do |s|
  # Fail-closed, call-site-derived stand-in for the unretrievable CardFlight-v4 4.3.1 binary.
  s.name         = 'CardFlight-v4'
  s.version      = '4.3.1'
  s.summary      = 'FAIL-CLOSED call-site-derived shim for CardFlight-v4 4.3.1 (no reader, no token, no transaction).'
  s.homepage     = 'https://cardflight.com'
  s.license      = { :type => 'shim', :text => 'Call-site-derived shim; contains no CardFlight code.' }
  s.authors      = { 'OpenUIKit golden capture' => 'none' }
  s.source       = { :git => 'local-shim' }
  s.module_name  = 'CardFlight'
  s.platform     = :ios, '10.0'
  s.swift_version = '4.0'
  s.source_files = 'Sources/*.swift'
end
