# Pull base image.
FROM centos:7

RUN yum install -y wget
RUN wget --no-cookies --no-check-certificate --header \
	"Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
	"http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm"
RUN yum localinstall -y jdk-8u60-linux-x64.rpm

ENV JAVA_HOME /usr/java/jdk1.8.0_60/jre

RUN wget -c "https://bintray.com/sbt/rpm/rpm" -O bintray-sbt-rpm.repo && \
	mv bintray-sbt-rpm.repo /etc/yum.repos.d/bintray-sbt-rpm.repo
RUN yum install -y sbt

RUN wget -c http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.rpm
RUN yum localinstall -y jprofiler_linux_9_2.rpm
