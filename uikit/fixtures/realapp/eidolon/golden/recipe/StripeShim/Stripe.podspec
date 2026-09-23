Pod::Spec.new do |s|
  # Fail-closed stand-in for Stripe 12.1.0 (lock) / 14.0.1 (Podfile).
  s.name         = 'Stripe'
  s.version      = '12.1.0'
  s.summary      = 'FAIL-CLOSED shim for the Stripe surface Eidolon calls (no network, no token, validator never valid).'
  s.homepage     = 'https://stripe.com'
  s.license      = { :type => 'shim', :text => 'Shim; contains no Stripe code.' }
  s.authors      = { 'OpenUIKit golden capture' => 'none' }
  s.source       = { :git => 'local-shim' }
  s.platform     = :ios, '10.0'
  s.source_files = 'Stripe/*.{h,m}'
  s.public_header_files = 'Stripe/*.h'
  s.requires_arc = true
end
