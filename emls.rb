# encoding: utf-8
require "nokogiri"
require "open-uri"

class Emls
  ENCODING =  'WINDOWS-1251'
  HEADERS = { "Host" => "www.emls.ru",
           "Connection" => "keep-alive",
        "Cache-Control" => "max-age=0",
               "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
           "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/28.0.1500.71 Chrome/28.0.1500.71 Safari/537.36",
                  "DNT" => "1",
      "Accept-Encoding" => "gzip,deflate,sdch",
      "Accept-Language" => "en-US,en;q=0.8",
               "Cookie" => "PHPSESSID=4a93cm3sfosil6s4j0r2dso296; ss=32fc50586616f12d6aebba01bb7121b3"
  }
  
  HOST = "http://www.emls.ru"
  PIONERSKAYA_URL = HOST + "/flats/?query=r0/1/r1/1/pmin/2800/pmax/3200/samin/28/samax/33/reg/2/dept/2/tr[]/37/sort1/7/dir1/1/s/1/sort2/1/dir2/2/interval/2"

  def initialize(html = nil)
    @html = html
  end

  def open_url
    open(PIONERSKAYA_URL, HEADERS) 
  end

  def doc
    @doc ||= -> do 
      str = @html ? @html : open_url.read
      str = str.encode("utf-8")
      # replace <br> to whitespace for easy parsing 
      doc = Nokogiri::HTML(str)
      doc.css("br").each{|br| br.replace " "} #, nil, ENCODING)
      doc
    end.call
  end

  def parse
    Parser.new(doc).parse
  end

  def to_s
    parse.map{|i| i.to_s}.join("\n\n===================================\n")
  end

  # for testing purposes. can be deleted at anytime
  def self.stored_html
    str = File.read(File.expand_path("../../emls.html", __FILE__))
    str.encode("utf-8")
    str
  end

  class BaseElement
    DEFAULT_VALUE = nil
    def initialize(doc)
      @doc = doc
    end
  end

  class Parser < BaseElement
    def parse
      @doc.css(".table_with_data").map{|item| ItemParser.new(item)}
    end
  end

  class ItemParser < BaseElement
    def initialize(doc)
      super(doc)
      @created_at = Time.now
    end

    def to_s
      methods = Emls::ItemParser.public_instance_methods(false) - [:to_s]
      methods.inject([]) do |data, m|
        data << "#{m}: #{send m}"
        data
      end.join("\n")
    end

    def address
      @address ||= td_text(1)
    end

    def link_to_map
      @link_to_map ||= link_by_image_title(td(0), "Панорама", false)
    end

    def metro
      @metro ||= -> do 
        text = td(1).children.to_s.strip
        # extract substring after </a> and before brackets 
        text
          .gsub(/^[\p{Graph}\p{Punct}\s]+<\/a>/, "")
          .gsub(/\(.*$/, "")
          .strip
      end.call
    end

    def district
      @district ||= address.scan(/^\p{Word}+/).first
    end

    def stage
      stages[:stage] 
    end

    def stage_amount
      stages[:stage_amount]
    end

    def house_type
      DEFAULT_VALUE
    end

    %w{rooms square live_square kitchen corridor}.each do |meth|
      define_method(meth){ details_hash[meth] }
    end

    def rest_room_type
      DEFAULT_VALUE
    end

    def price
      td_text(4).scan(/^\d+/).first
    end

    def price_per_meter
      (price.to_f / square.to_f).to_i.to_s
    end

    def contact_link 
      a = td(5).search("a").first
      link_from_a a if a 
    end

    def contacts
      td_text(5)
    end

    def details
      td_text(2)
    end

    def description
      td_text(6)
    end

    def created_at
      @created_at 
    end

    def link_to_details
      @link_to_details ||= link_by_image_title(td(0), "Подробнее...")
    end

    def placed_at
      @placed_at ||= td_text(5).scan(/\d\d\.\d\d\.\d{4}$/).first
    end

    private
    def td(index)
      @doc.search("td")[index]
    end

    def td_text(index)
      td(index).text.gsub(/\s+/, " ").strip
    end

    def attribute_from_tag(tag, attr_name)
      tag.attributes[attr_name].to_s
    end

    def link_from_path(path)
      HOST + path
    end

    def link_from_a(a, path = true)
      link = attribute_from_tag(a, "href")
      path ? link_from_path(link) : link
    end

    def stages
      @stages ||= -> do 
        str = td_text(3)
        arr = str.scan(/(\d+)\/(\d+)/).first
        {stage: arr[0], stage_amount: arr[1]}
      end.call
    end

    def details_hash
      @details_hash ||= -> do  
        # clean string from new line symbols
        str = td_text(2)
        
        details = {}
        details["rooms"]    = delete_template str, /^(\d+).\./           
        details["kitchen"]  = delete_template str, /кух\.\s+(#{float_r})/
        details["corridor"] = delete_template str, /кор\.\s+(#{float_r})/
        s, ls               = delete_template(str, /(#{float_r})\/(#{float_r})/, true)
        details["square"], details["live_square"] = s, ls
        details
       end.call
    end

    # regexp for float number
    def float_r
      /\d+\.*\d*/
    end

    # gets data and deletes matched template from string
    def delete_template(str, regexp, result_as_array = false)
      res = str.scan(regexp).first
      str.gsub!(regexp, "")
      if res
        result_as_array ? res : res.first
      end
    end

    def link_by_image_title(node, title, path=true)
      a_tag = node 
        .search("img[title='#{title}']")
        .first
        .parent
      link_from_a(a_tag, path)
    end
  end
end

=begin
  td#0: 
    link#0: link to details (find by title of image ="Подробнее")
    link#1: link to map  (find by title of image ="Панорама")
  td#1: 
    Address
    link#0: address link
  td#2 
    details 
  td#3
    stage
  td#4
    price
  td#5
    agent
    link#0: link to agent
  td#6
    description
=end

=begin
<tr class="html_table_tr_1 table_with_data" data-href="/fullinfo/1/349766.html">
  <td class="fc" align="center">
    <input type="checkbox" name="ids[]" value="349766" onclick="addMarkWithCity( 1, 349766, this.checked, 'spb' );">
    <br>
    <a href="/fullinfo/1/349766.html" target="_blank" title="Подробнее...">
      <img src="/themes/theme1/images/info.gif" alt="i" title="Подробнее...">
    </a>
    <a href="http://maps.yandex.ru/?text=%D0%EE%F1%F1%E8%FF%2C%20%D1%E0%ED%EA%F2-%CF%E5%F2%E5%F0%E1%F3%F0%E3%2C%20%C8%F1%EF%FB%F2%E0%F2%E5%EB%E5%E9%20%EF%F0.%2C%2011&amp;z=13&amp;l=map%2Cstv&amp;ol=stv&amp;oll=30.29138890%2C60.00555900&amp;oid" target="_blank">
      <img src="/themes/theme1/images/360.gif" alt="Панорама" title="Панорама">
    </a>
  </td>
  <td>
    Приморский<br>
    <a href="#" onclick="javascript:window.open('http://www.emls.ru/onmap/?query=r/2/rd/2/rdd/14/s/1334/hn/11', '_blank', 'width=500,height=500,scrollbars=0'); return false;">Испытателей пр., 11</a>
    <br>Пионерская</td>
  <td>1к. 31/17.7<br>кух. 6.2</td>
  <td>3/12<br>Есть</td>
  <td>2985 (96 за кв/м)<br>ипотека<br>Прямая;</td>
  <td>
    <a href="/agent/192073.html?query=type/full" target="_blank">Троицкий дом Выгодина Н.В.</a>
    <br>8(906)263-32-96<br>17.08.2013
  </td>
  <td>
    <a href="/fullinfo/1/349766.html" target="_blank" style="text-decoration:none;color:#000000;">
      Панельный, Крупно-панельн.; окна На улицу, ремонт Произведен, пол Линолеум, гор.вода Теплоцентр, Застекленная лоджия, СУ-Раздельный, ванна Отдельная, мусороп. Есть<br>пп документы готовы!
    </a>
  </td>
</tr>
=end

