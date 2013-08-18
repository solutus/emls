require_relative "../emls.rb"
require "minitest/autorun"

describe Emls do
  before do
    @emls = Emls.new(HTML)
  end

  describe ".parse" do 
    it "returns array" do 
      @emls.parse.must_be_instance_of Array
    end
  end

  describe Emls::ItemParser do 
    MAP = {
      address: "Приморский Байконурская ул., 5к1 пр. Просвещения (пеш 10м)",
      district: "Приморский",
      metro: "пр. Просвещения",
      link_to_details: "http://www.emls.ru/fullinfo/1/372848.html",
      link_to_map: "http://maps.yandex.ru/?text=%D0%EE%F1%F1%E8%FF%2C%20%D1%E0%ED%EA%F2-%CF%E5%F2%E5%F0%E1%F3%F0%E3%2C%20%C1%E0%E9%EA%EE%ED%F3%F0%F1%EA%E0%FF%20%F3%EB.%2C%205%EA1&z=13&l=map%2Cstv&ol=stv&oll=30.27749970%2C59.99730500&oid",
      stage: "6", 
      stage_amount: "9" , 
      rooms: "1", 
      square: "32.2", 
      live_square: "18", 
      kitchen: "6.2", 
      corridor: "5", 
      price: "3100", 
      price_per_meter: "96",
      contact_link: "http://www.emls.ru/agent/161817.html?query=type/full",
      contacts: "АБСОЛЮТ Сити Мальковская И.В. 440-9999, 450-9999 06.08.2013", 
      placed_at: "06.08.2013", 
      details: "1к. 32.2/18 кух. 6.2 кор. 5",
      description: %q{Панельный, Крупно-панельн., (г.п. 1977); ремонт Произведен, ТЕЛ-Есть, гор.вода Теплоцентр, СУ-Раздельный ПП, б.3х лет, зелень Высокоразвитая инфраструктура, между двумя станциями метро "Пионерская" и "Комендантский пр." в пешей доступности, все рядом: гипермаркеты, магазины, объекты социальной сферы (дет.садики, школы, поликлиники), выезд на КАД. ЗСД. Балкона нет. Квартира в собст-ти более 3-х лет, подойдет любая ипотека. Прямая продажа. Тел. 8-921-567-41-12 Ирина},
    }

    before do 
      @item = @emls.parse[0]
    end

    MAP.each do |meth, result|
      it "#{meth} is equal #{result}" do 
        @item.send(meth).must_equal result
      end
    end

    it "has created at" do 
      ((Time.now - @item.created_at) < 1).must_equal true
    end



  end

  HTML = %q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
      <head></head>
      <body>
        <tr class="html_table_tr_1 table_with_data" data-href="/fullinfo/1/372848.html">
          <td class="fc" align="center">
            <input type="checkbox" name="ids[]" value="372848" onclick="addMarkWithCity( 1, 372848, this.checked, 'spb' );">
            <br>
            <a href="/fullinfo/1/372848.html" target="_blank" title="Подробнее...">
              <img src="/themes/theme1/images/info.gif" alt="i" title="Подробнее...">
            </a>
            <a href="http://maps.yandex.ru/?text=%D0%EE%F1%F1%E8%FF%2C%20%D1%E0%ED%EA%F2-%CF%E5%F2%E5%F0%E1%F3%F0%E3%2C%20%C1%E0%E9%EA%EE%ED%F3%F0%F1%EA%E0%FF%20%F3%EB.%2C%205%EA1&amp;z=13&amp;l=map%2Cstv&amp;ol=stv&amp;oll=30.27749970%2C59.99730500&amp;oid" target="_blank">
              <img src="/themes/theme1/images/360.gif" alt="Панорама" title="Панорама">
            </a>
          </td>
          <td>
            Приморский<br>
            <a href="#" onclick="javascript:window.open('http://www.emls.ru/onmap/?query=r/2/rd/2/rdd/14/s/1296/hn/5/hk/1', '_blank', 'width=500,height=500,scrollbars=0'); return false;">
              Байконурская ул., 5к1
            </a><br>пр. Просвещения<br>(пеш 10м)
          </td>
          <td>1к. 32.2/18<br>кух. 6.2 кор. 5</td>
          <td>6/9<br>пот-к 2.6м</td>
          <td>3100 (96 за кв/м)<br>ипотека<br>Прямая;</td>
          <td>
            <a href="/agent/161817.html?query=type/full" target="_blank">АБСОЛЮТ Сити Мальковская И.В.</a>
            <br>440-9999, 450-9999<br>06.08.2013
          </td>
          <td>
            <a href="/fullinfo/1/372848.html" target="_blank" style="text-decoration:none;color:#000000;">
              Панельный, Крупно-панельн., (г.п. 1977); ремонт Произведен, ТЕЛ-Есть, гор.вода Теплоцентр, СУ-Раздельный<br>ПП, б.3х лет, зелень
          Высокоразвитая инфраструктура, между двумя станциями метро "Пионерская" и "Комендантский пр." в пешей доступности, все рядом: гипермаркеты, магазины, объекты социальной сферы (дет.садики, школы, поликлиники), выезд на КАД. ЗСД.
          Балкона нет. Квартира в собст-ти более 3-х лет, подойдет любая ипотека. Прямая продажа. Тел. 8-921-567-41-12 Ирина
            </a>
          </td>
        </tr>
      </body>
    </html>
    }
end
