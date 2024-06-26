## LMS installation script
echo "Installing LMS and its dependencies..."
INSTALLING="/home/volumio/lms-plugin.installing"

if [ ! -f $INSTALLING ]; then

	touch $INSTALLING
	arch=$(arch)
	echo "Detected architecture: " $arch

	if [ ! -f /usr/sbin/squeezeboxserver ] || [ $1 =  "force" ];
	then
		apt-get update

		echo "Installing ShellInAbox..."
		apt-get install -f shellinabox -y

		echo "Installing php-server..."
		apt-get install -f php -y


		# Download latest version of LMS
		echo "Downloading installation package..."
		if [ ! -d /home/volumio/logitechmediaserver ];
		then
			mkdir /home/volumio/logitechmediaserver
		else
			rm -rf /home/volumio/logitechmediaserver/*.*
		fi
		
		LATEST="https://lyrion.org/lms-server-repository/latest.xml"
		LATEST_LOCATION="/home/volumio/logitechmediaserver/latest.xml"

		wget -O $LATEST_LOCATION $LATEST

		cd /home/volumio/logitechmediaserver/

		if [ -f $LATEST_LOCATION ]; then
		echo "Latest.xml downloaded successfully"
		else
		echo "Failed to download Latest.xml"
		exit 1
		fi
		apt-get install libxml2-utils


		FILE="$(xmllint --xpath "//deb/@url" $LATEST_LOCATION | awk -F'"' '{print $2}')"
		echo "FILE: $FILE"
		wget -O /home/volumio/logitechmediaserver/logitechmediaserver.deb $FILE
				
		# Move the binary to the expected directory
		if [ -f /etc/squeezeboxserver ];
		then
			mv /etc/squeezeboxserver /usr/sbin/squeezeboxserver
		fi
		# Install package and dependencies
		apt-get -f install -y
		echo "Installing downloaded package"
		dpkg --force-depends -i /home/volumio/logitechmediaserver/logitechmediaserver.deb
		

		# Needed for SSL connections; e.g. github
		apt --fix-broken install
		apt-get install libio-socket-ssl-perl libcrypt-openssl-rsa-perl lame unzip -y
		apt-get -f install -y

		# These directories still use the old name; probably legacy code
		echo "Fixing directory rights"
		mkdir /var/lib/squeezeboxserver
		chown -R volumio:volumio /var/lib/squeezeboxserver

		# Add the squeezeboxserver user to the audio group
		usermod -aG audio squeezeboxserver

		# Add the systemd unit
		echo "Using the prepared systemd unit"
		rm -rf /etc/systemd/system/logitechmediaserver.service
		ln -fs /data/plugins/music_service/lms/unit/logitechmediaserver.service /etc/systemd/system/logitechmediaserver.service

		# Stop service and fix rights for preference folder
		service logitechmediaserver stop

		# Fix rights issue for preference, cache and log directory, needs execute right for prefs
		chmod 777 -R /var/lib/squeezeboxserver

		# Tidy up
		rm -rf /home/volumio/logitechmediaserver

		# Verify if the directory is deleted
		if [ ! -d /home/volumio/logitechmediaserver ]; then
		echo "Directory /home/volumio/logitechmediaserver deleted successfully"
		else
		echo "Failed to delete directory /home/volumio/logitechmediaserver"
		exit 1
		fi

		# Reload the systemd unit
		systemctl daemon-reload

		# Fix Right in case of
		chown -R volumio:volumio /home/volumio/Blissanalyser

		sleep 3

	else
		echo "A technical error occurred, the plugin already exists, but installation was able to continue. If you just want to install LMS again, try the force parameter: [sh script.sh force]."
	fi

	rm $INSTALLING
 #required to end the plugin install
	echo "plugininstallend"
else
	echo "Plugin is already installing! Not continuing..."
fi