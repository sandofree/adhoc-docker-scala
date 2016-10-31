FROM debian:8

# install jdk1.8

RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> \
	/etc/apt/sources.list.d/java-8-debian.list && \
	echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> \
	/etc/apt/sources.list.d/java-8-debian.list && \
	echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list &&  \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 99E82A75642AC823 && \
	apt-get update -y && \
	apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default mongo-org redis-server sbt cron unzip wget

# install jprofiler
RUN wget -c http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.sh && bash jprofiler_linux_9_2.sh

ONBUILD COPY . /data

# set internal sbt repo and crontab
ONBUILD RUN if [ -e /data/script/sbt-repositories ] ; then cp /data/script/sbt-repositories ~/.sbt/repositories ; fi
ONBUILD RUN if [ -e /data/script/crontab ] ; then cp /data/script/crontab /etc/crontab && touch /var/log/cron.log ; fi

# build and test
ONBUILD RUN service mongodb restart && service redis-server restart \ && cd /data \
	&& sbt -Dsbt.override.build.repos=true test \
	&& sbt -Dsbt.override.build.repos=true dist \
	&& unzip -o target/universal/*.zip

# run cron and project
ONBUILD CMD cron && cd /data/target/universal/*/bin && \
	export proj_name=`sbt settings name | tail -1 | cut -d' ' -f2` && \
	./$proj_name -Dconfig.resource=prod.conf
