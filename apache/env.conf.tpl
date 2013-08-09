ServerName vonc-VirtualBox
Listen @PORT_HTTP_STATUS@
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule ldap_module modules/mod_ldap.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
LoadModule authnz_ldap_module modules/mod_authnz_ldap.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
Include conf/extra/httpd-manual.conf
<IfModule mod_status.c>
#
# Allow server status reports generated by mod_status,
# with the URL of http://servername/server-status
# Uncomment and change the ".example.com" to allow
# access from other hosts.
#
ExtendedStatus On
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from localhost ip6-localhost <my ip address>
#    Allow from .example.com
</Location>

</IfModule>

SSLCACertificateFile "@H@/apache/global_ca.crt"
LDAPTrustedGlobalCert CA_BASE64 "@H@/openldap/global_ca.crt"
#LDAPVerifyServerCert off

SSLRandomSeed startup file:/dev/urandom 512
SSLRandomSeed connect file:/dev/urandom 512
SSLPassPhraseDialog  builtin
AddType application/x-x509-ca-cert .crt
AddType application/x-pkcs7-crl    .crl
SSLSessionCache        "shmcb:@H@/apache/ssl_scache(512000)"
SSLSessionCacheTimeout  300
# http://stackoverflow.com/a/15633390/6309
Mutex sysvsem default
#SSLMutex  "file:@H@/apache/ssl_mutex"

<AuthnProviderAlias ldap myldap>
  AuthLDAPBindDN cn=Manager,dc=example,dc=com
  AuthLDAPBindPassword secret
  AuthLDAPURL ldap://localhost:@PORT_LDAP_TEST@/dc=example,dc=com?uid?sub?(objectClass=*)
</AuthnProviderAlias>

# LDAP_START
<AuthnProviderAlias ldap companyldap>
  AuthLDAPBindDN "@LDAP_BINDDN@"
  AuthLDAPBindPassword @LDAP_PASSWORD@
  AuthLDAPURL @LDAP_URL@
</AuthnProviderAlias>
# LDAP_END

# GitWeb on @PORT_HTTP_GITWEB@
Listen @PORT_HTTP_GITWEB@
<VirtualHost @FQN@:@PORT_HTTP_GITWEB@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/gitweb
    Alias /git @H@/gitweb
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory @H@/gitweb>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All
        order allow,deny
        Allow from all

        AuthBasicProvider myldap companyldap

        AuthType Basic
        AuthName "LDAP authentication for ITSVC Prod GitWeb repositories"
        Require valid-user

        AddHandler cgi-script cgi
        DirectoryIndex gitweb.cgi
        
        RewriteEngine Off
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^[a-zA-Z0-9_\-]+\.git/?(\?.*)?$ /gitweb.cgi%{REQUEST_URI} [L,PT]
    </Directory>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    LogLevel Debug ssl:info
    CustomLog "@H@/apache/gitweb_ssl_request_log" \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/apache/gitweb_error_log"
    TransferLog "@H@/apache/gitweb_access_log"
</VirtualHost>

# GitHttp on @PORT_HTTP_HGIT@
Listen @PORT_HTTP_HGIT@
<VirtualHost @FQN@:@PORT_HTTP_HGIT@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SetEnv GIT_PROJECT_ROOT @H@/repositories
    SetEnv GIT_HTTP_EXPORT_ALL
    SetEnv GITOLITE_HTTP_HOME @H@
    ScriptAlias /hgit/ @H@/sbin/gitolite-shell/
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Location /hgit>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        AuthName "LDAP authentication for ITSVC Smart HTTP Git repositories"
        AuthType Basic
        AuthBasicProvider myldap companyldap
        # AuthzLDAPAuthoritative Off
        Require valid-user
        AddHandler cgi-script cgi
    </Location>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    CustomLog "@H@/apache/githttp_ssl_request_log" \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/apache/githttp_error_log"
    TransferLog "@H@/apache/githttp_access_log"
</VirtualHost>


# CGit on @PORT_HTTP_CGIT@
Listen @PORT_HTTP_CGIT@
<VirtualHost @FQN@:@PORT_HTTP_CGIT@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/cgit
    Alias /cgit @H@/cgit
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory @H@/cgit>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All
        order allow,deny
        Allow from all

        AddHandler cgi-script .cgi .pl
        DirectoryIndex cgit.pl

        #RewriteEngine on
 
        SetEnv GIT_PROJECT_ROOT=@H@/repositories
 
        AuthName "LDAP authentication for ITSVC CGit repositories"
        AuthType Basic
        AuthBasicProvider myldap companyldap
        # AuthzLDAPAuthoritative Off
        Require valid-user

        #RewriteCond %{REQUEST_FILENAME} !-f
        #RewriteCond %{REQUEST_FILENAME} !-d 
        #RewriteRule "^(.*)/(.*)/(HEAD|info/refs|objects/(info/[^/]+|[0-9a-f]{2}/[0-9a-f]{38}|pack/pack-[0-9a-f]{40}\.(pack|idx))|git-(upload|receive)-pack)$" /git-http-backend.cgi/$1.git/$2 [NS,L,QSA]
 
        #RewriteCond %{REQUEST_FILENAME} !-f
        #RewriteCond %{REQUEST_FILENAME} !-d
        #RewriteRule ^/$ /cgit.pl/ [L,PT,NS]
        #RewriteRule ^/.+ /cgit.pl$0 [L,PT,NS]

    </Directory>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    CustomLog "@H@/apache/gitcgit_ssl_request_log" \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/apache/gitcgit_error_log"
    TransferLog "@H@/apache/gitcgit_access_log"
    LogLevel info
</VirtualHost>

IncludeOptional @H@/gitlab/apache*.cnf

IncludeOptional @H@/gitlist/apache*.cnf
