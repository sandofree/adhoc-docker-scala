# Pull base image.
FROM dockerfile/ubuntu

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -y && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# install sbt and tools
RUN echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-get install -y --force-yes sbt redis-server mongodb cron unzip

# set timezone to CN
RUN echo "Asia/Harbin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

# Define default command.
CMD ["bash"]
