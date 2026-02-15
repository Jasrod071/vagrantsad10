N = "10" # Tu número de clase
iniciales = "jjsr"

Vagrant.configure("2") do |config|

  # 1. Definición del equipo gw (CON APARTADO 10)
  config.vm.define "gw" do |gw|
    gw.vm.box = "bento/ubuntu-24.04"
    gw.vm.hostname = "gw-#{iniciales}"
    gw.vm.network "forwarded_port", guest: 1194, host: 11194, protocol: "udp"
    # eth1: WAN
    gw.vm.network "private_network", ip: "203.0.113.254", netmask: "255.255.255.0", virtualbox__intnet: "red_wan"
    # eth2: DMZ
    gw.vm.network "private_network", ip: "172.1.#{N}.1", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    # eth3: LAN
    gw.vm.network "private_network", ip: "172.2.#{N}.1", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    
    # PROVISIÓN CON VARIABLE LDAP (Apartado 10)
    gw.vm.provision "shell", 
      path: "gw/provision.sh",
      env: { "LDAP_PASS" => "adeasysl" }
    
    gw.vm.provision "shell", run: "always", path: "gw/firewall/firewall.sh"   
    
    gw.vm.provider "virtualbox" do |vb|
        vb.name = "gw"
        vb.gui = false
        vb.memory = "768"
        vb.cpus = 1
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # 2. IDP en la LAN
  config.vm.define "idp" do |idp|
    idp.vm.box = "bento/ubuntu-24.04"
    idp.vm.hostname = "idp-#{iniciales}"
    idp.vm.network "private_network", ip: "172.2.#{N}.2", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    idp.vm.provision "shell", path: "idp/provision.sh"
    idp.vm.provision "shell",
        run: "always",
        inline:  "ip route del default && ip route add default via 172.2.#{N}.1"        
    idp.vm.provider "virtualbox" do |vb|
        vb.name = "idp-lan"
        vb.memory = "512"
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # 3. Adminpc en la LAN
  config.vm.define "adminpc" do |adminpc|
    adminpc.vm.box = "generic/alpine319"
    adminpc.vm.hostname = "adminpc-#{iniciales}"
    adminpc.vm.network "private_network", ip: "172.2.#{N}.10", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    adminpc.vm.provision "shell", path: "adminpc/provision.sh"
    adminpc.vm.provision "shell",
        run: "always",
        inline:  "ip route del default && ip route add default via 172.2.#{N}.1"   
    adminpc.vm.provider "virtualbox" do |vb|
        vb.name = "adminpc-lan"
        vb.memory = "128"
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # 4. Empleado en la LAN
  config.vm.define "empleado" do |empleado|
    empleado.vm.box = "generic/alpine319"
    empleado.vm.hostname = "empleado-#{iniciales}"
    empleado.vm.network "private_network", ip: "172.2.#{N}.100", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    empleado.vm.provision "shell", path: "empleado/provision.sh"
    empleado.vm.provision "shell",
        run: "always",
        inline:  "ip route del default && ip route add default via 172.2.#{N}.1"   
    empleado.vm.provider "virtualbox" do |vb|
        vb.name = "empleado-lan"
        vb.memory = "128"
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # 5. Proxy en DMZ
  config.vm.define "proxy" do |proxy|
    proxy.vm.box = "bento/ubuntu-24.04"
    proxy.vm.hostname = "proxy-#{iniciales}"
    proxy.vm.network "private_network", ip: "172.1.#{N}.2", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    proxy.vm.provision "shell", path: "proxy/provision.sh"
    proxy.vm.provision "shell",
        run: "always",
        inline:  "ip route del default && ip route add default via 172.1.#{N}.1"        
    proxy.vm.provider "virtualbox" do |vb|
        vb.name = "proxy-dmz"
        vb.memory = "1024"
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # 6. WWW en DMZ
  config.vm.define "www" do |www|
    www.vm.box = "generic/alpine319"
    www.vm.hostname = "www-#{iniciales}"
    www.vm.network "private_network", ip: "172.1.#{N}.3", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    www.vm.provision "shell", path: "www/provision.sh"
    www.vm.provision "shell",
        run: "always",
        inline:  "ip route del default && ip route add default via 172.1.#{N}.1"     
    www.vm.provider "virtualbox" do |vb|
        vb.name = "www-dmz"
        vb.memory = "512"
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

end 

