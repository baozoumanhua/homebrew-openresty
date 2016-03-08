require 'formula'

class Openresty < Formula
  homepage 'http://openresty.org/'

  stable do
    url 'https://openresty.org/download/openresty-1.9.7.3.tar.gz'
    sha1 '1a2029e1c854b6ac788b4d734dd6b5c53a3987ff'
  end

  depends_on 'pcre'
  depends_on 'postgresql' => :optional
  depends_on 'geoip' => :optional

  # openresty options
  option 'without-luajit', "Compile *without* support for the Lua Just-In-Time Compiler"
  option 'with-postgresql', "Compile with support for direct communication with PostgreSQL database servers"
  option 'with-iconv', "Compile with support for converting character encodings"

  option 'with-debug', "Compile with support for debug logging but without proper gdb debugging symbols"

  # nginx options
  option 'with-webdav', "Compile with ngx_http_dav_module"
  option 'with-gunzip', "Compile with ngx_http_gunzip_module"
  option 'with-geoip', "Compile with ngx_http_geoip_module"
  option 'with-stub_status', "Compile with ngx_http_stub_status_module"

  skip_clean 'logs'

  def install
    pcre = Formula["pcre"]
    openssl = Formula["openssl"]

    cc_opt = "-I#{pcre.include} -I#{openssl.include}"
    ld_opt = "-L#{pcre.lib} -L#{openssl.lib}"

    args = ["--prefix=#{prefix}",
      "--with-http_ssl_module",
      "--with-pcre",
      "--with-pcre-jit",
      "--sbin-path=#{bin}/openresty",
      "--conf-path=#{etc}/openresty/nginx.conf",
      "--pid-path=#{var}/run/openresty.pid",
      "--lock-path=#{var}/openresty/nginx.lock",
      "--with-cc-opt=#{cc_opt}",
      "--with-ld-opt=#{ld_opt}"
    ]

    args << "--with-http_dav_module" if build.with? 'webdav'
    args << "--with-http_gunzip_module" if build.with? 'gunzip'
    args << "--with-http_geoip_module" if build.with? 'geoip'
    args << "--with-http_stub_status_module" if build.with? 'stub_status'

    # Debugging mode, unfortunately without debugging symbols
    if build.with? 'debug'
      args << '--with-debug'
      args << '--with-dtrace-probes'
      args << '--with-no-pool-patch'

      # this allows setting of `debug.sethook` in luajit
      unless build.without? 'luajit'
        args << '--with-luajit-xcflags=-DLUAJIT_ENABLE_CHECKHOOK'
      end

      opoo "Openresty will be built --with-debug option, but without debugging symbols. For debugging symbols you have to compile it by hand."
    end

    # OpenResty options
    args << "--with-lua51" if build.without? 'luajit'

    args << "--with-http_postgres_module" if build.with? 'postgresql'
    args << "--with-http_iconv_module" if build.with? 'iconv'

    system "./configure", *args

    system "make"
    system "make install"
  end
end
