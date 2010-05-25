<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id: scripts.xsl 3446 2007-08-11 11:08:11Z manuel $ -->

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

  <!-- Build as user (y) or as root (n)? -->
  <xsl:param name="sudo" select="y"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">
    <xsl:if test="(count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump'])) and
                  @id != 'locale-issues' and @id != 'xorg7' and
                  @id != 'x-setup'">

        <!-- The file names -->
      <xsl:variable name="filename" select="@id"/>

        <!-- Package name (use "Download FTP" by default. If empty, use "Download HTTP" -->
      <xsl:variable name="package">
        <xsl:choose>
          <xsl:when
            test="string-length(sect2[@role='package']/itemizedlist/listitem[2]/para/ulink/@url)
            &gt; '10'">
            <xsl:call-template name="package_name">
              <xsl:with-param name="url"
                select="sect2[@role='package']/itemizedlist/listitem[2]/para/ulink/@url"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="package_name">
              <xsl:with-param name="url"
                select="sect2[@role='package']/itemizedlist/listitem[1]/para/ulink/@url"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

        <!-- FTP dir name -->
      <xsl:variable name="ftpdir">
        <xsl:call-template name="ftp_dir">
          <xsl:with-param name="package" select="$package"/>
        </xsl:call-template>
      </xsl:variable>

        <!-- The build order -->
      <xsl:variable name="position" select="position()"/>
      <xsl:variable name="order">
        <xsl:choose>
          <xsl:when test="string-length($position) = 1">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:when test="string-length($position) = 2">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Depuration code -->
      <xsl:message>
        <xsl:text>SCRIPT is </xsl:text>
        <xsl:value-of select="concat($order,'-',$filename)"/>
        <xsl:text>&#xA;   PACKAGE is </xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>&#xA;    FTPDIR is </xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;&#xA;</xsl:text>
      </xsl:message>

        <!-- Creating the scripts -->
      <exsl:document href="{$order}-z-{$filename}" method="text">
        <xsl:text>#!/bin/bash&#xA;set -e&#xA;&#xA;</xsl:text>
        <xsl:choose>
          <!-- Package page -->
          <xsl:when test="sect2[@role='package'] and not(@id = 'xorg7-app' or
                          @id = 'xorg7-data' or @id = 'xorg7-driver' or
                          @id = 'xorg7-font' or @id = 'xorg7-lib' or
                          @id = 'xorg7-proto' or @id = 'xorg7-util')">
            <!-- Variables -->
            <xsl:text>SRC_ARCHIVE=$SRC_ARCHIVE&#xA;</xsl:text>
            <xsl:text>FTP_SERVER=$FTP_SERVER&#xA;&#xA;PACKAGE=</xsl:text>
            <xsl:value-of select="$package"/>
            <xsl:text>&#xA;PKG_DIR=</xsl:text>
            <xsl:value-of select="$ftpdir"/>
            <xsl:text>&#xA;SRC_DIR=$SRC_DIR&#xA;&#xA;</xsl:text>
            <!-- Download code and build commands -->
            <xsl:apply-templates select="sect2">
              <xsl:with-param name="package" select="$package"/>
              <xsl:with-param name="ftpdir" select="$ftpdir"/>
            </xsl:apply-templates>
            <!-- Clean-up -->
            <xsl:if test="not(@id='mesalib')">
              <xsl:text>cd $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
              <xsl:text>rm -rf $UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
            </xsl:if>
            <xsl:if test="@id='xorg7-server'">
              <xsl:text>cd $SRC_DIR/MesaLib
UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
rm -rf $UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
            </xsl:if>
          </xsl:when>
          <!-- Xorg7 pseudo-packages -->
          <xsl:when test="contains(@id,'xorg7') and not(@id = 'xorg7-server')">
            <xsl:text>SRC_DIR=$SRC_DIR

cd $SRC_DIR
mkdir -p xc
cd xc&#xA;</xsl:text>
            <xsl:apply-templates select="sect2" mode="xorg7"/>
          </xsl:when>
          <!-- Non-package page -->
          <xsl:otherwise>
            <xsl:apply-templates select=".//screen"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>exit</xsl:text>
      </exsl:document>

    </xsl:if>
  </xsl:template>

<!--======================= Sub-sections code =======================-->

  <xsl:template match="sect2">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:text>mkdir -p $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
        <xsl:text>cd $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
        <xsl:apply-templates select="itemizedlist/listitem/para">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
        </xsl:apply-templates>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>
if [[ -e unpacked ]] ; then
  UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  [[ -n $UNPACKDIR ]] &amp;&amp; [[ -d $UNPACKDIR ]] &amp;&amp; rm -rf $UNPACKDIR
fi
tar -xvf $PACKAGE > unpacked
UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
cd $UNPACKDIR&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen | .//para/command"/>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig&#xA;&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates select=".//screen"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sect2" mode="xorg7">
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:apply-templates select="itemizedlist/listitem/para" mode="xorg7"/>
      </xsl:when>
      <xsl:when test="not(@role)">
        <xsl:text>SRC_ARCHIVE=$SRC_ARCHIVE
FTP_SERVER=$FTP_SERVER&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen" mode="sect-ver"/>
        <xsl:text>mkdir -p ${section}&#xA;cd ${section}&#xA;</xsl:text>
        <xsl:apply-templates select="../sect2[@role='package']/itemizedlist/listitem/para" mode="xorg7-patch"/>
        <xsl:text>for line in $(grep -v '^#' ../${sect_ver}.wget) ; do
  if [[ ! -f ${line} ]] ; then
    if [[ -f $SRC_ARCHIVE/Xorg/${section}/${line} ]] ; then
      cp $SRC_ARCHIVE/Xorg/${section}/${line} ${line}
    elif [[ -f $SRC_ARCHIVE/Xorg/${line} ]] ; then
      cp $SRC_ARCHIVE/Xorg/${line} ${line}
    elif [[ -f $SRC_ARCHIVE/${section}/${line} ]] ; then
      cp $SRC_ARCHIVE/${section}/${line} ${line}
    elif [[ -f $SRC_ARCHIVE/${line} ]] ; then
      cp $SRC_ARCHIVE/${line} ${line}
    else
      wget ${FTP_SERVER}conglomeration/Xorg/${line} || \
      wget http://xorg.freedesktop.org/releases/individual/${section}/${line}
    fi
  fi
done
md5sum -c ../${sect_ver}.md5
cp ../${sect_ver}.wget ../${sect_ver}.wget.orig
cp ../${sect_ver}.md5 ../${sect_ver}.md5.orig&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>for package in $(grep -v '^#' ../${sect_ver}.wget) ; do
  packagedir=$(echo $package | sed 's/.tar.bz2//')
  tar -xf ${package}
  cd ${packagedir}&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen | .//para/command"/>
        <xsl:text>  cd ..
  rm -rf ${packagedir}
  sed -i "/${package}/d" ../${sect_ver}.wget
  sed -i "/${package}/d" ../${sect_ver}.md5
done
mv ../${sect_ver}.wget.orig ../${sect_ver}.wget
mv ../${sect_ver}.md5.orig ../${sect_ver}.md5&#xA;</xsl:text>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig&#xA;&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates select=".//screen"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

<!--==================== Download code =======================-->

  <xsl:template name="package_name">
    <xsl:param name="url" select="foo"/>
    <xsl:param name="sub-url" select="substring-after($url,'/')"/>
    <xsl:choose>
      <xsl:when test="contains($sub-url,'/')">
        <xsl:call-template name="package_name">
          <xsl:with-param name="url" select="$sub-url"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($sub-url,'?')">
            <xsl:value-of select="substring-before($sub-url,'?')"/>
          </xsl:when>
          <xsl:when test="contains($sub-url,'.patch')"/>
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ftp_dir">
    <xsl:param name="package" select="foo"/>
    <!-- A lot of hardcoded dir names. Not full revised yet. -->
    <xsl:choose>
        <!-- cdparanoia -->
      <xsl:when test="contains($package, '-III')">
        <xsl:text>cdparanoia</xsl:text>
      </xsl:when>
        <!-- DobBook 3.1 -->
      <xsl:when test="contains($package, 'docbk31')">
        <xsl:text>docbk</xsl:text>
      </xsl:when>
        <!-- gc -->
      <xsl:when test="contains($package, 'gc6')">
        <xsl:text>gc</xsl:text>
      </xsl:when>
        <!-- ISO-codes -->
      <xsl:when test="contains($package, 'iso-codes')">
        <xsl:text>iso-codes</xsl:text>
      </xsl:when>
        <!-- JPEG -->
      <xsl:when test="contains($package, 'jpegsrc')">
        <xsl:text>jpeg</xsl:text>
      </xsl:when>
        <!-- lynx -->
      <xsl:when test="contains($package, 'lynx')">
        <xsl:text>lynx</xsl:text>
      </xsl:when>
        <!-- ntp -->
      <xsl:when test="contains($package, 'ntp')">
        <xsl:text>ntp</xsl:text>
      </xsl:when>
        <!-- OpenLDAP -->
      <xsl:when test="contains($package, 'openldap')">
        <xsl:text>openldap</xsl:text>
      </xsl:when>
        <!-- Open Office -->
      <xsl:when test="contains($package, 'OOo')">
        <xsl:text>OOo</xsl:text>
      </xsl:when>
        <!-- pine -->
      <xsl:when test="contains($package, 'pine')">
        <xsl:text>pine</xsl:text>
      </xsl:when>
        <!-- portmap -->
      <xsl:when test="contains($package, 'portmap')">
        <xsl:text>portmap</xsl:text>
      </xsl:when>
        <!-- psutils -->
      <xsl:when test="contains($package, 'psutils')">
        <xsl:text>psutils</xsl:text>
      </xsl:when>
        <!-- qpopper -->
      <xsl:when test="contains($package, 'qpopper')">
        <xsl:text>qpopper</xsl:text>
      </xsl:when>
        <!-- QT -->
      <xsl:when test="contains($package, 'qt-x')">
        <xsl:text>qt-x11-free</xsl:text>
      </xsl:when>
        <!-- sendmail -->
      <xsl:when test="contains($package, 'sendmail')">
        <xsl:text>sendmail</xsl:text>
      </xsl:when>
        <!-- Slib -->
      <xsl:when test="contains($package, 'slib')">
        <xsl:text>slib</xsl:text>
      </xsl:when>
        <!-- TCL -->
      <xsl:when test="contains($package, 'tcl')">
        <xsl:text>tcl</xsl:text>
      </xsl:when>
        <!-- tcpwrappers -->
      <xsl:when test="contains($package, 'tcp_wrappers')">
        <xsl:text>tcp_wrappers</xsl:text>
      </xsl:when>
        <!-- TeTeX -->
      <xsl:when test="contains($package, 'tetex')">
        <xsl:text>tetex</xsl:text>
      </xsl:when>
        <!-- Tidy -->
      <xsl:when test="contains($package, 'tidy')">
        <xsl:text>tidy</xsl:text>
      </xsl:when>
        <!-- Tk -->
      <xsl:when test="contains($package, 'tk8')">
        <xsl:text>tk</xsl:text>
      </xsl:when>
        <!-- unzip -->
      <xsl:when test="contains($package, 'unzip')">
        <xsl:text>unzip</xsl:text>
      </xsl:when>
        <!-- wireless_tools -->
      <xsl:when test="contains($package, 'wireless_tools')">
        <xsl:text>wireless_tools</xsl:text>
      </xsl:when>
        <!-- whois -->
      <xsl:when test="contains($package, 'whois')">
        <xsl:text>whois</xsl:text>
      </xsl:when>
        <!-- XOrg -->
      <xsl:when test="contains($package, 'X11R6')">
        <xsl:text>Xorg</xsl:text>
      </xsl:when>
        <!-- zip -->
      <xsl:when test="contains($package, 'zip2')">
        <xsl:text>zip</xsl:text>
      </xsl:when>
        <!-- General rule -->
      <xsl:otherwise>
        <xsl:variable name="cut"
          select="translate(substring-after($package, '-'), '0123456789', '0000000000')"/>
        <xsl:variable name="package2">
          <xsl:value-of select="substring-before($package, '-')"/>
          <xsl:text>-</xsl:text>
          <xsl:value-of select="$cut"/>
        </xsl:variable>
        <xsl:value-of select="substring-before($package2, '-0')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <!-- This depend on all package pages having both "Download HTTP" and "Download FTP" lines -->
      <xsl:when test="contains(string(),'HTTP')">
        <xsl:text>if [[ ! -f $PACKAGE ]] ; then&#xA;</xsl:text>
        <!-- SRC_ARCHIVE may have subdirectories or not -->
        <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$PACKAGE $PACKAGE&#xA;</xsl:text>
        <xsl:text>  elif [[ -f $SRC_ARCHIVE/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PACKAGE $PACKAGE&#xA;  else&#xA;</xsl:text>
        <!-- The FTP_SERVER mirror -->
        <xsl:text>    wget ${FTP_SERVER}conglomeration/$PKG_DIR/$PACKAGE</xsl:text>
        <!-- Upstream HTTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:text> || \&#xA;    wget </xsl:text>
          <xsl:choose>
            <xsl:when test="contains(ulink/@url,'?')">
              <xsl:value-of select="substring-before(ulink/@url,'?')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ulink/@url"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains(string(),'FTP')">
        <!-- Upstream FTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:text> || \&#xA;    wget </xsl:text>
          <xsl:value-of select="ulink/@url"/>
        </xsl:if>
        <xsl:text>&#xA;  fi&#xA;fi&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
        <xsl:text>&#x20;&#x20;$PACKAGE" | md5sum -c -&#xA;</xsl:text>
      </xsl:when>
      <!-- Patches -->
      <xsl:when test="contains(string(ulink/@url),'.patch')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para" mode="xorg7">
    <xsl:if test="contains(string(ulink/@url),'.md5') or
                  contains(string(ulink/@url),'.wget')">
      <xsl:text>wget </xsl:text>
      <xsl:value-of select="ulink/@url"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para" mode="xorg7-patch">
    <xsl:if test="contains(string(ulink/@url),'.patch')">
      <xsl:text>wget </xsl:text>
      <xsl:value-of select="ulink/@url"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

<!--======================== Commands code ==========================-->

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:if test="@role = 'root' and $sudo = 'y'">
        <xsl:text>sudo sh -c '</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="userinput"/>
      <xsl:if test="@role = 'root' and $sudo = 'y'">
        <xsl:text>'</xsl:text>
      </xsl:if>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen" mode="sect-ver">
    <xsl:text>section=</xsl:text>
    <xsl:value-of select="substring-before(substring-after(string(),'mkdir '),' &amp;')"/>
    <xsl:text>&#xA;sect_ver=</xsl:text>
    <xsl:value-of select="substring-before(substring-after(string(),'-c ../'),'.md5')"/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="para/command">
    <xsl:if test="(contains(string(),'test') or
            contains(string(),'check'))">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="substring-before(string(),'make')"/>
      <xsl:text>make -k</xsl:text>
      <xsl:value-of select="substring-after(string(),'make')"/>
      <xsl:text> || true&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='xorg7-server']">
        <xsl:text>$SRC_DIR/MesaLib</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
