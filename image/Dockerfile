FROM public.ecr.aws/lambda/python:3.8

RUN pip3 install --upgrade pip \
  && pip3 install awscli certbot certbot-dns-route53

COPY app/* ./

CMD [ "app.handler" ]
