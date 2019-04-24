# ENABLE SSH BY DEFAULT 
if ! grep -Fxq "systemctl start ssh" /etc/rc.local
then
    echo 'Enabling automatic start of ssh on bootup...'
    sudo sed -i '19i\systemctl start ssh' /etc/rc.local
    # code if not found
fi
# END ENABLE SSH BY DEFAULT

# GET NECESSARY PACKAGES
sudo apt-get update -y
sudo apt-get install -y vim git build-essential pkg-config git cmake libssl-dev uuid-dev valgrind

if ! grep -Fxq "CURL_ROOT" ~/.bashrc
then
    printf 'Enabling automatic start of ssh on bootup...'
    echo 'export CURL_ROOT=/home/pi/curl_install' >> ~/.bashrc 
    # code if not found
fi

if ! grep -Fxq "LD_LIBRARY_PATH" ~/.bashrc
then 
    echo 'export LD_LIBRARY_PATH'
    echo 'export LD_LIBRARY_PATH=$CURL_ROOT/lib' >> ~/.bashrc
fi

printf 'Setting variables by calling bashrc'
source ~/.bashrc

# BUILD AND INSTALL NEW CURL
wget https://curl.haxx.se/download/curl-7.64.1.tar.gz
mkdir $CURL_ROOT
mkdir curl_source
tar -C curl_source -xzvf curl-7.64.1.tar.gz
cd curl_source/curl-7.64.1/
./configure --prefix=$CURL_ROOT --disable-shared --without-zlib --with-ssl --enable-static
make -j
make install
# END GET NECESARY PACKAGES 

# BUILD THE SDK
cd ~
cd azure-iot-sdk-c
mkdir cmake && cd cmake
cmake -Drun_unittests=ON -Drun_e2e_tests=ON -DCMAKE_BUILD_TYPE=Debug -DCURL_LIBRARY=$CURL_ROOT/lib/libcurl.a -DCURL_INCLUDE_DIR=$CURL_ROOT/include  ..
cd iothub_client/tests/iothubclient_mqtt_e2e
cmake --build .
sudo setcap cap_net_raw,cap_net_admin+ep iothubclient_mqtt_e2e_exe
# END BUILD THE SDK

# RUN THE E2E TEST
read -p "Have you added your credentials? " -n 1 -r
echo   # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    printf "running iothubclient_mqtt_e2e_exe...\n"
else 
    printf "please export the necessary IOTHUB variables before running the test.\n"
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
./iothubclient_mqtt_e2e_exe
# END RUN THE E2E TEST