function fail_with_message() {
    1>&2 echo $1
    exit 1
}

ARCH=`/usr/bin/arch`

JAVA_PATH=/usr/lib/jvm/java-11-amazon-corretto.$ARCH/bin/java
if [ -x $JAVA_PATH ]; then
    echo "Amazon Corretto 11 JRE is installed."
else
    fail_with_message "Amazon Corretto 11 JRE is not installed. Failing."
fi

JAVAC_PATH=/usr/lib/jvm/java-11-amazon-corretto.$ARCH/bin/javac
if [ -x $JAVAC_PATH ]; then
    echo "Amazon Corretto 11 JDK is installed."
else
    fail_with_message "Amazon Corretto 11 JDK is not installed. Failing."
fi