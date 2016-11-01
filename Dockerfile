FROM debian:7

# install jdk1.8

RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
	echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
	echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list &&  \
	echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 99E82A75642AC823 && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get update -y && \
	echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
	echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
	apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default mongodb-org redis-server sbt cron unzip wget

# install jprofiler
# RUN wget -c http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.sh && bash jprofiler_linux_9_2.sh

ONBUILD COPY . /data

# set internal sbt repo and crontab
ONBUILD RUN if [ -e /data/script/sbt-repositories ] ; then cp /data/script/sbt-repositories ~/.sbt/repositories ; fi
ONBUILD RUN if [ -e /data/script/crontab ] ; then cp /data/script/crontab /etc/crontab && touch /var/log/cron.log ; fi

# build and test
ONBUILD RUN service mongod restart && service redis-server restart \ && cd /data \
	&& sbt -Dsbt.override.build.repos=true test \
	&& sbt -Dsbt.override.build.repos=true dist \
	&& unzip -o target/universal/*.zip

# run cron and project
ONBUILD CMD cron && cd /data/target/universal/*/bin && \
	export proj_name=`sbt settings name | tail -1 | cut -d' ' -f2` && \
	./$proj_name -Dconfig.resource=prod.conf -Dfile.encoding=UTF8
