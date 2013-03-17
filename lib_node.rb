require 'rubygems'
require 'json'

class LibNode
  class VisGraph
    attr_accessor :routers_by_node
    attr_accessor :originators_by_router
    attr_accessor :routers_per_client
    
    # "Primary" originator of a tt_mac 
    def originating_node(tt_mac)
      parse_data
      originators_by_router[ routers_by_node[tt_mac] ] || routers_by_node[tt_mac]
    end

    def home_node(tt_mac)
      parse_data
      if originator = originating_node(tt_mac)
        mac = LibNode.vpn_to_node_mac(originator)
        LibNode.mac_to_node_id(mac)
      end
    end
    
    def clients_per_originator
      parse_data
      res = {}
      routers_per_client.each_key do |n|
      	o = originating_node n
      	unless o.match /fast/ #ignore server
      	  res[o] = 0 unless res[o]
      	  res[o] +=1
        end
      end
      res.each_pair {|k,v| res[k] -= 2 if v >= 2}
    end
    
    def total_client_count
      parse_data
      sum = 0
      clients_per_originator.each_value {|v| sum += v}
      sum
    end
    
    def graph_data
      @graph_data ||= IO.popen("sudo batctl_vd_json") do |pipe|
        JSON.parse "[ #{ pipe.readlines.join ', ' } ]"
      end
    end
    
    private
    def parse_data
      if routers_by_node.nil? || originators_by_router.nil?
        self.routers_by_node = {}; self.originators_by_router = {}; self.routers_per_client = {}
        graph_data.each do |node|
          self.routers_by_node[ node ["gateway"] ]         = node["router"]  if node ["gateway"]
          self.originators_by_router[ node["secondary"]  ] = node["of"]      if node["secondary"]
          self.routers_per_client[ node ["gateway"] ]       = node["router"]  if node["label"] == 'TT'
        end
      end
    end
  end
  
  
  # Konvertiere die MAC des Nodes (nach Aufkleber) in die Mac des VPN-interfaces (Batman-adv originator)
  # Formel geamaess Luebecker fastd up-Script
  def self.node_to_vpn_mac(node_mac)
    # Formel im Up-Script
    ## MAC-Adresse fuer interface auswuerfeln
    #oIFS=\"$IFS\"; IFS=\":\"; set -- $macaddr; IFS=\"$oIFS\"
    #b2mask=0x02
    #macaddr=$(printf \"%02x:%s:%s:%02x:%s:%s\" $(( 0x$1 | $b2mask )) $2 $3 $(( (0x$4 + 1) % 0x100 )) $5 $6)
  
    # Implemtation in Ruby
    b2mask=0x02
    octets = node_mac.split(':').map {|part| part.to_i(16)}
  
    # Erstes octed: b2-mask Anwenden -> Somit: Locally administered mac
    octets[0] = octets[0] | b2mask
  
    #4. Octed: Hochzaehlen, und hoffen, dass keine Kollision auftritt
    octets[3] = octets[3] + 1 % 0x100
    octets.map {|o| "%02x" % o}.join ':'
  end

  # Konvertiere die MAC des VPN-interfaces (Batman-adv originator) in die des Nodes (nach Aufkleber)
  # Invertiert die Berechnung aus dem Luebecker up-Script
  def self.vpn_to_node_mac(node_mac)
    # Implemtation in Ruby
    b2mask=0x02
    octets = node_mac.split(':').map {|part| part.to_i(16)}
  
    # Erstes octed: b2-mask Invertiert anwenden -> Somit: Globally administered mac
    octets[0] = octets[0] & ~b2mask
  
    #4. Octed: um 1 decr.
    octets[3] = octets[3] - 1 % 0x100
    octets.map {|o| "%02x" % o}.join ':'
  end
  
  def self.node_id_to_mac(node_id)
    node_id.scan(/../).join ':'
  end
  
  def self.mac_to_node_id(mac)
    mac.split(/:/).join ''
  end
end

