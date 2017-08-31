FROM hlcup/build

RUN rm -rf /opt/app
WORKDIR /opt/hlcup

COPY run.sh .
COPY hlcup.tar.gz .


RUN tar zxvf hlcup.tar.gz

# Set exposed ports
EXPOSE 80

ENV PORT=80 MIX_ENV=prod REPLACE_OS_VARS=true TERM=xterm
#CMD ["/opt/app/bin/hlcup","foreground"]
CMD ["/opt/hlcup/run.sh"]
