FROM debian:8

# Install JDK1.8
RUN echo "Install Java..." && \
	(echo "deb http://repos.azulsystems.com/debian stable main" | tee /etc/apt/sources.list.d/zulu.list) && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xB1998361219BD9C9 && \
	mkdir -p /var/cache/apt/archives/partial && touch /var/cache/apt/archives/lock && chmod 640 /var/cache/apt/archives/lock && \
	apt-get install -f && apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update -y && \
	apt-get install -y --force-yes --no-install-recommends zulu-8 wget ca-certificates unzip

# Install sbt
RUN echo "Install sbt..." && \
	wget -c 'https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.3.8/sbt-launch.jar' && \
	mv sbt-launch.jar /var && \
	echo '#!/bin/bash' > /usr/bin/sbt && \
	echo 'java -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -jar /var/sbt-launch.jar "$@"' >> /usr/bin/sbt && \
	chmod u+x /usr/bin/sbt && \
	mkdir -p /root/.sbt && \
	echo '[repositories]' > /root/.sbt/repositories && \
	echo 'local' >> /root/.sbt/repositories && \
	echo 'huaweicloud-ivy: https://mirrors.huaweicloud.com/repository/ivy/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]' >> /root/.sbt/repositories && \
	echo 'huaweicloud-maven: https://mirrors.huaweicloud.com/repository/maven/' >> /root/.sbt/repositories && \
	echo 'sbt-plugin-releases: https://dl.bintray.com/sbt/sbt-plugin-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]' >> /root/.sbt/repositories && \
	echo 'appadhoc: http://registry-prod.appadhoc.com:30080/repository/release/' >> /root/.sbt/repositories

# Config Timezone
RUN echo "Asia/Harbin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

# Build
ONBUILD COPY ./build.sbt /data/build.sbt
ONBUILD COPY ./project /data/project
ONBUILD COPY ./script /data/script
ONBUILD RUN (if [ -e /data/script/sbt-repositories ] ; then cp /data/script/sbt-repositories /root/.sbt/repositories ; fi) && \
	cd /data && sbt -Dsbt.override.build.repos=true update
ONBUILD COPY . /data
ONBUILD RUN echo "Build..." && \
	cd /data && sbt -Dsbt.override.build.repos=true -Dfile.encoding=UTF-8 dist && \
	cd /data/target/universal/ && unzip -o *.zip

# Install
ONBUILD RUN cd /data && export proj_name=`sbt settings name | tail -1 | cut -d' ' -f2 | tr -dc [:print:] | sed 's/\[0m//g'` && \
	mkdir -p /release/${proj_name} && mv /data/target/universal/${proj_name}* /release && \
	cd /release/${proj_name}*/bin && \
	ln -s `pwd`/${proj_name} /entrypoint

# Cleanup
ONBUILD RUN rm -r /data

# Run
ONBUILD CMD ["/entrypoint", "-Dconfig.resource=prod.conf", "-Dfile.encoding=UTF8"]
