#!/usr/bin/env sh

#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls -ld "$PRG"
    link=`ls -l "$PRG" | awk '{print $NF}'`
    case $link in
        /*) PRG="$link" ;;
        *) PRG=`dirname "$PRG"`"/$link" ;;
    esac
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Add default JVM options
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# Use the maximum available, or set MAX_FD != maximum.
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar


# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" -a "$darwin" = "false" -a "$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS \"-Xdock:name=$APP_NAME\" \"-Xdock:icon=$APP_HOME/media/gradle.icns\""
fi

# For Cygwin or MSYS, switch paths to Windows format before running java
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`

    JAVACMD=`cygpath --unix "$JAVACMD"`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 3 -type d -name gradle 2>/dev/null | head -1`
    SEP=""
    for dir in $ROOTDIRSRAW; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    CYGPATTERN="(^($ROOTDIRS))"
    if [ -n "$JAVA_HOME" ] ; then
        JAVA_HOME_CYGWIN=`cygpath --path --windows "$JAVA_HOME"`
        SEP=""
        for dir in $JAVA_HOME_CYGWIN; do
            JAVA_HOME_CYGWIN="$JAVA_HOME_CYGWIN$SEP$dir"
            SEP=":"
        done
        CLASSPATH=`cygpath --path --windows "$CLASSPATH"`
    fi
    CLASSPATH=`cygpath --path --windows "$CLASSPATH"`

    if [ -n "$CYGPATH_PREFIX" ] ; then
        CLASSPATH="$CYGPATH_PREFIX;$CLASSPATH"
    fi

    # Is the arguments string Windows format and not Arm?
    if [ "$msys" = "true" ] ; then
        isArm=false
    fi
    # positive integer iff successful
    MATCHES=`expr "$JAVACMD" : '\([^ ]*\)'`
    CYGWIN_JAVACMD="$MATCHES"

    # Dealing with Cygwin search path except simple cases.
    if [ "$BASIC_INSTALL" = true ] ; then
        CYGPATH_PATTERN="(^($ROOTDIRS))"
        CYGPATTERN="(^($ROOTDIRS))"
    else
        case "$JAVA_HOME_CYGWIN" in
          *";"* )
            # if the path contains ";" then it is assumed Cygwin is in use and files
            # from "cygpath" will be in unix format. If this is not the case,
            # comment this out.
            CYGWIN_JAVACMD="$CYGWIN_JAVACMD"
            ;;
        esac

        # classpath might contain spaces now...
        CLASSPATH=`cygpath --path --windows "$CLASSPATH"`

        JAVA_HOME_CYGWIN=`cygpath --path --windows "$JAVA_HOME_CYGWIN"`
    fi

    STARTDIR="`pwd`"
    CYGDIR="`cygpath --windows "$STARTDIR"`"
    # Try the split Ant way of specifying a classpath.
    if [ -f "$APP_HOME/gradle/wrapper/gradle-wrapper.jar" ] ; then
        # Classpath is important!
        CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
        if [ -n "$JAVA_HOME_CYGWIN"  ] ; then
            JAVA_HOME_CYGWIN=`cygpath --unix "$JAVA_HOME_CYGWIN"`
            [ -n "$JAVA_PATH_CYGWIN"  ] && JAVA_PATH_CYGWIN=`cygpath --unix "$JAVA_PATH_CYGWIN"`
        fi
    else
        if [ ! -f "$APP_HOME/gradle/wrapper/gradle-wrapper.jar"  ] ; then
            die "Gradle wrapper not found in path."
        fi
    fi

    # Ending a string with a backslash is a problem on Windows.
    case "$CYGDIR" in
      *\\) CYGDIR=`cygpath --windows "$CYGDIR"`.
            ;;
    esac
    if [ -d "$CYGDIR" ] ; then
        JAVA_HOME_CYGWIN=`cygpath --unix "$JAVA_HOME"`
        [ -z "$JAVA_PATH_CYGWIN" ] && JAVA_PATH_CYGWIN=.
        # We build the pattern for arguments to be converted via cygpath
        ROOTDIRSRAW=`find -L / -maxdepth 3 -type d 2>/dev/null`
        for dir in $ROOTDIRSRAW; do
            ROOTDIRS="$ROOTDIRS$SEP$dir"
            SEP=":"
        done
        # Messed up, revert back
        ROOTDIRS=""
        SEP="|"
        ROOTDIRSRAW=`find -L / -maxdepth 3 -type d -name gradle 2>/dev/null | head -1`
        for dir in $ROOTDIRSRAW; do
            ROOTDIRS="$ROOTDIRS$SEP$dir"
            SEP="|"
        done
        OURCYGPATTERN="(^($ROOTDIRS))"
        CYGPATTERN="(^($ROOTDIRS))"
        # Add a user-defined pattern to the cygpath arguments
        if [ "$GRADLE_CYGPATTERN" != "" ] ; then
            OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
        fi
        # Now convert the arguments - kludge to limit ourselves to /bin/sh
        i=0
        for arg in "$@" ; do
            CHECK=`echo "$arg"|awk '{print $1}'`
            CHECK2=`echo "$CHECK" | sed 's/ //g'`
            if [ "$CHECK2" != "" ] ; then
                ipath=`convertpath "$arg"`
                if [ -z "$ipath" ] ; then
                    echo "Error converting $arg "
                fi
                iarg1=`expr "$ipath" : '\([^ ]*\)'`
                if [ ! -f "$iarg1" ] ; then
                    echo "Could not convert $arg1 "
                fi
            fi
            i=`expr $i + 1`
        done
        CYGPATTERN=""

    fi
else
    # add a trailing slash to forceUnix
    CLASSPATH=`cygpath --path --unix "$CLASSPATH"`
fi

# add default JVM options
eval set -- $DEFAULT_JVM_OPTS "$@"

# Collect all arguments for the java command, stacking in reverse order:
#   * args from the command line
#   * the main class name
#   * -classpath
#   * -D...sysproperties
#   * --module-path (only if needed)
#   * DEFAULT_JVM_OPTS, JAVA_OPTS, and GRADLE_OPTS environment variables.

# For Cygwin or MSYS, switch paths to Windows format before running java
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    eval set -- $DEFAULT_JVM_OPTS -Xms1024m -Xmx1024m -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
else
    eval set -- $DEFAULT_JVM_OPTS -Xms1024m -Xmx1024m -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
fi

exec "$JAVACMD" "$@"
