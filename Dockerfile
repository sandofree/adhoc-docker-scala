FROM centos:7

# install jdk1.8
RUN yum install -y wget
RUN wget --no-cookies --no-check-certificate --header \
	"Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
	"http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm"
RUN yum localinstall -y jdk-8u60-linux-x64.rpm

ENV JAVA_HOME /usr/java/jdk1.8.0_60/jre

# install sbt
RUN wget -c "https://bintray.com/sbt/rpm/rpm" -O bintray-sbt-rpm.repo && \
	mv bintray-sbt-rpm.repo /etc/yum.repos.d/bintray-sbt-rpm.repo
RUN yum install -y sbt

# install jprofiler
RUN wget -c http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.rpm
RUN yum localinstall -y jprofiler_linux_9_2.rpm

# install backend stack for test
RUN echo $'[mongodb-org-3.2] \n\
name=MongoDB Repository \n\
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/ \n\
gpgcheck=1 \n\
enabled=1 \n\
gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc' > /etc/yum.repos.d/mongodb-org.repo
RUN wget -r --no-parent -A 'epel-release-*.rpm' http://dl.fedoraproject.org/pub/epel/7/x86_64/e/ && \
	rpm -Uvh dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-*.rpm
RUN yum install -y cron redis mongodb-org cron unzip

# set timezone
RUN timedatectl set-timezone "Asia/Harbin"

ONBUILD COPY . /data

# set internal sbt repo and crontab
ONBUILD RUN if [ -e /data/script/sbt-repositories ] ; then cp /data/script/sbt-repositories ~/.sbt/repositories ; fi
ONBUILD RUN if [ -e /data/script/crontab ] ; then cp /data/script/crontab && touch /var/log/cron.log ; fi

# build and test
ONBUILD RUN systemctl restart mongodb && systemctl restart redis \ && cd /data \
	&& sbt -Dsbt.override.build.repos=true test \
	&& sbt -Dsbt.override.build.repos=true dist \
	&& unzip -o target/universal/*.zip

# run cron and project
ONBUILD CMD cron && cd /data/target/universal/*/bin && \
	export proj_name=`sbt settings name | tail -1 | cut -d' ' -f2` && \
	./$proj_name -Dconfig.resource=prod.conf
