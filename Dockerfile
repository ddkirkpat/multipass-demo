
FROM python:3.7-alpine

#Set environment
ENV HOME=/opt

# Add source code files
ADD app ${HOME}/app

#Expose ports for webservice
EXPOSE 80
EXPOSE 5000

# Set working directory
WORKDIR ${HOME}

# Run pip to install required python packages
RUN pip3 install -r app/requirements.txt

# Set entrypoint and run app.py
ENTRYPOINT [ "python3" ]
CMD [ "app/exampleapp.py" ]