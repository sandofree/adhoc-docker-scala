FROM debian:8

# install jdk1.8, mongodb, redis
RUN echo "Install Java, MongoDB, Redis..." && \
  (echo "deb http://repos.azulsystems.com/debian stable main" | tee /etc/apt/sources.list.d/zulu.list) && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xB1998361219BD9C9 && \
	mkdir -p /var/cache/apt/archives/partial && touch /var/cache/apt/archives/lock && chmod 640 /var/cache/apt/archives/lock && \
	apt-get install -f && apt-get clean && rm -rf /var/lib/apt/lists/* && \
	apt-get update -y && \
	apt-get install -y --force-yes --no-install-recommends zulu-8 mongodb redis-server redis-tools wget ca-certificates unzip procps

# install sbt
RUN echo "Install sbt..." && \
	wget -c 'https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.0.0-M4/sbt-launch.jar' && \
	mv sbt-launch.jar /var && \
	echo '#!/bin/bash' > /usr/bin/sbt && \
	echo 'java -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -jar /var/sbt-launch.jar "$@"' >> /usr/bin/sbt && \
	chmod u+x /usr/bin/sbt && \
	mkdir -p ~/.sbt && \
  echo '[repositories]' > ~/.sbt/repositories && \
  echo 'local' >> ~/.sbt/repositories && \
  echo 'huaweicloud-ivy: https://mirrors.huaweicloud.com/repository/ivy/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]' >> ~/.sbt/repositories && \
  echo 'huaweicloud-maven: https://mirrors.huaweicloud.com/repository/maven/' >> ~/.sbt/repositories

# install jprofiler - Uncomment this when we need performance profiling.
#RUN echo "Install JProfiler" && \
#	wget -c http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.sh && bash jprofiler_linux_9_2.sh -q

# config timezone
RUN echo "Asia/Harbin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

ONBUILD COPY ./project /data/project
ONBUILD COPY ./build.sbt /data/build.sbt
ONBUILD RUN (if [ -e /data/script/sbt-repositories ] ; then mkdir -p ~/.sbt && cp /data/script/sbt-repositories ~/.sbt/repositories ; fi) && \
	cd /data && sbt update -Dsbt.override.build.repos=true
ONBUILD COPY . /data

# build and test
ONBUILD RUN echo service mongodb restart && service redis-server restart \ && cd /data && \
	sbt -Dsbt.override.build.repos=true -Dfile.encoding=UTF-8 test && \
	sbt -Dsbt.override.build.repos=true -Dfile.encoding=UTF-8 dist && \
	cd /data/target/universal/ && unzip -o *.zip

# run cron and project
ONBUILD RUN cd /data && export proj_name=`sbt settings name | tail -1 | cut -d' ' -f2 | tr -dc [:print:] | sed 's/\[0m//g'` && \
	mkdir -p /release/${proj_name} && mv /data/target/universal/${proj_name}* /release && \
	cd /release/${proj_name}*/bin && \
	ln -s `pwd`/$proj_name /entrypoint

# cleanup
ONBUILD RUN rm -r /data

ONBUILD CMD ["/entrypoint", "-Dconfig.resource=prod.conf", "-Dfile.encoding=UTF8"]
