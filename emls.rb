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
  BASE_URL = HOST +  "/flats/?query="
  FLAT_TYPES = {
    "Студия"  => 0,
    "1 комн." => 1,
    "2 комн." => 2,
    "3 комн." => 3,
    "4 комн." => 4,
    "5 комн." => 5,
  }
  DISTRICTS = {
             "Не указано" => 0,
         "Адмиралтейский" => 38,
       "Василеостровский" => 43,
             "Выборгский" => 4,
            "Калининский" => 6,
              "Кировский" => 7,
      "Красногвардейский" => 8,
         "Красносельский" => 9,
             "Московский" => 12,
                "Невский" => 13,
          "Петроградский" => 20,
             "Приморский" => 14,
            "Фрунзенский" => 15,
            "Центральный" => 39
  }

  METROS = {
             "Не указано" => 0,
         "А.Hевского пл." => 52,
                 "Автово" => 5,
         "Адмиралтейская" => 101,
          "Академическая" => 20,
             "Балтийская" => 8,
        "Большевиков пр." => 49,
           "Бухарестская" => 103,
       "Василеостровская" => 2,
          "Ветеранов пр." => 3,
           "Владимирская" => 11,
             "Волковская" => 93,
          "Восстания пл." => 13,
             "Выборгская" => 16,
            "Горьковская" => 34,
          "Гостиный Двор" => 32,
        "Гражданский пр." => 21,
         "Дачное ж.д.ст." => 97,
              "Девяткино" => 22,
            "Достоевская" => 47,
            "Дыбенко ул." => 48,
           "Елизаровская" => 45,
               "Звездная" => 24,
         "Звенигородская" => 94,
        "Кировский завод" => 6,
      "Комендантский пр." => 91,
       "Красное Село ст." => 96,
     "Крестовский остров" => 56,
                "Купчино" => 23,
              "Ладожская" => 50,
             "Ленина пл." => 15,
          "Ленинский пр." => 4,
                 "Лесная" => 17,
          "Лиговский пр." => 46,
          "Ломоносовская" => 44,
             "Маяковская" => 12,
          "Международная" => 104,
             "Московская" => 25,
      "Московские ворота" => 28,
           "Мужества пл." => 18,
               "Нарвская" => 7,
            "Невский пр." => 33,
         "Новочеркасская" => 51,
         "Обводный Канал" => 100,
                "Обухово" => 42,
                 "Озерки" => 39,
            "Парк Победы" => 26,
                 "Парнас" => 92,
          "Петроградская" => 35,
             "Пионерская" => 37,
        "Политехническая" => 19,
             "Приморская" => 53,
           "Пролетарская" => 43,
        "Просвещения пр." => 40,
             "Пушкинская" => 10,
               "Рыбацкое" => 41,
                "Садовая" => 30,
             "Сенная пл." => 31,
               "Спасская" => 95,
             "Спортивная" => 54,
         "Старая Деревня" => 57,
    "Технологический и-т" => 9,
               "Удельная" => 38,
            "Фрунзенская" => 29,
           "Черная речка" => 36,
           "Чернышевская" => 14,
             "Чкаловская" => 55,
            "Электросила" => 27
  }

  INTERVALS = {
              "сегодня" => 4,
                "2 дня" => 5,
                "3 дня" => 7,
                "4 дня" => 8,
               "5 дней" => 9,
               "6 дней" => 10,
               "неделя" => 1,
             "2 недели" => 6,
                "месяц" => 2,
      "без ограничений" => 3
  }

  def initialize(params={})
    @search_params = compose_params(params)
    @url =  compose_url @search_params
  end

  def flats
    @flats ||= Parser.new(docs).parse.sort_by(&:price)
  end

  def to_s
    parse.map{|i| i.to_s}.join("\n\n===================================\n")
  end

  def docs
    initial_doc = doc @url
    [initial_doc] + pages_urls(initial_doc).map{|url| doc url }
  end

  def open_url(url)
    res = open(url, HEADERS).read
    sleep(5)
    res
  end

  def doc(url)
    str = open_url(url)
    str = str.encode("utf-8")
    # replace <br> to whitespace for easy parsing
    doc = Nokogiri::HTML(str)
    doc.css("br").each{|br| br.replace " "} #, nil, ENCODING)
    doc
  end

  def pages_urls(doc)
    doc
      .css("a[title*='страница']")
      .map(&:attributes)
      .map{|attrs| attrs["href"].value }
      .uniq
      .map{|path| HOST + path }
  end

  def compose_params(**opts)
    { flat_types: [0, 1],
      min_price: 2800,
      max_price: 3200,
      min_square: 28,
      max_square: 33,
      districts: [4, 14],
      metros: [20, 37, 40, 57],
      interval: 2 }.merge(opts)
  end

  def compose_url(flat_types: nil,
                  min_price:  nil,
                  max_price:  nil,
                  min_square: nil,
                  max_square: nil,
                  districts:  nil,
                  metros:     nil,
                  interval:   nil)
    url = BASE_URL

    params = []
    params += flat_types.map{|type| "r#{type}/1"}

    params << "pmin/#{min_price}" if min_price
    params << "pmax/#{max_price}" if max_price
    params << "samin/#{"%.2f" % min_square}" if min_square
    params << "samax/#{"%.2f" % max_square}" if max_square

    params << "reg/2/dept/2" # Saint-Petersburg
    params << "dist/#{parametrize_array(districts)}" unless districts.empty?
    params << "tr[]/#{parametrize_array(metros)}" unless metros.empty?

    params << "sort1/7/dir1/1/s/1/sort2/1/dir2/2" # sorting
    params << "interval/#{interval}"

    url + params.join("/")
  end

  def parametrize_array(arr)
    arr.sort.join "-"
  end

  def save
    DB.transaction do
      search = Search.find_or_create(@search_params)
      iteration = Iteration.create search_id: search.id
      flats.each do |f|
        f.iteration_id = iteration.id
        f.save
      end
    end
    true
  end


  class Parser
    def initialize(docs)
      @docs = docs
    end

    def parse
      @docs.map{|doc| parse_doc doc }.flatten
    end

    def parse_doc(doc)
      doc
        .css(".table_with_data")
        .select{|tr| tr.css("td").size >= 7} # select standard objects
        .map{|item| ItemParser.new item }
    end
  end

  class ItemParser
    SHORT_FORMAT_FIELDS = [:address, :description, :details,
                           :price, :stage, :stage_amount]
    DEFAULT_VALUE = nil
    attr_accessor :iteration_id

    def initialize(doc)
      @doc = doc
      @created_at = Time.now
    end

    def as_json
      ConfigData[:tables][:flat_snapshots].keys.inject({}) do |res, field|
        res[field] = send field if respond_to? field
        res
      end
    end

    def save
      data = as_json
      flat = Flat.find_or_create(uid: uid)
      data.merge!({flat_id: flat.id})
      FlatSnapshot.create data
    end

    def uid
      link_to_details
    end

    def to_s(format = :short)
      methods = self.class.public_instance_methods(false) - [:to_s]
      if format == :short
        methods = methods.select{|m| SHORT_FORMAT_FIELDS.include? m }
      end
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
        details["square"] = s || delete_template(str, /(#{float_r})/)
        details["live_square"] = ls
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

