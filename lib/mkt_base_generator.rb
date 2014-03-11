class MktBaseGenerator
  include MultiJobsProcess

  @queue = :low
  
  def max
    20
  end

  def execute data
    csv_content = CSV.generate(col_sep: ";") do |csv|
      map(data).each{|u| csv << [u.first_name, u.email, u.criado_em, u.birthday,u.authentication_token,u.total.to_s,u.tem_pedido,u.ticket_medio,u.qtde_pedido ,u.ultimo_pedido,u.tipo, u.profile]}
    end

    sufix = "%02d" % data['index']

    filename = "fragment-#{sufix}.csv"
    path = "tmp/#{filename}"
    File.open(path, "w", encoding: "ISO-8859-1") { |io| io << csv_content }
    MarketingReports::S3Uploader.new('base_geral').copy_file(filename)
  end

  def map data
    User.find_by_sql("select uuid, first_name, DATE_FORMAT(created_at,'%Y-%m-%d') as criado_em, email, DATE_FORMAT(birthday,'%Y-%m-%d') as birthday, authentication_token, tem_pedido, ticket_medio, qtde_pedido,
    DATE_FORMAT(ultimo_pedido, '%Y-%m-%d') as ultimo_pedido, IF(half_user = 'TRUE', 'Half', 'Full') as tipo, profile , total from (select u.id as uuid, (
    IFNULL((select sum(c.value) from credits c where c.user_credit_id = uc.id and c.is_debit = 0 and c.activates_at <= date(now()) and c.expires_at >= date(now())),0) -
    IFNULL((select sum(c.value) from credits c where c.user_credit_id = uc.id and c.is_debit = 1 and c.activates_at <= date(now()) and c.expires_at >= date(now())), 0)
  ) total, ( select IF(count(o.id) > 0, 'SIM', 'NAO' )) tem_pedido, count(o.id) qtde_pedido,  IFNULL((sum(o.gross_amount) / count(o.id)), 0) ticket_medio, (select MAX(o.created_at)) ultimo_pedido from users u left join user_credits uc on u.id = uc.user_id and uc.credit_type_id = 1 left join orders o on u.id = o.user_id and o.state in ('authorized', 'delivery', 'picking', 'delivering')
      where u.id >= #{data['first']} and u.id < #{data['last']} AND u.reseller = false
      group by u.id
  ) as tmp join users on tmp.uuid = users.id")
  end

  def split_data
    total = User.count
    num_of_records = total / max
    left = total % max + 1

    datas = (0...max).map do |i|
      first = i * num_of_records
      last = num_of_records * (i+1) - 1
      last += left if i == (max - 1)
      {first: first, last: last}
    end
  end

  def join  
    connection = Fog::Storage.new provider: 'AWS'
    dir = connection.directories.get(Rails.env.production? ? "olook-ftp" : "olook-ftp-dev")
    files = dir.files.select{|file| file.key.match( /base_geral\/fragment/) }.map{|file| file.key}

    begin
      open("tmp/base_atualizada.csv", 'wb') do |f|
        # header
        f << ['first_name', 'email address', 'criado_em', 'aniversario', 'auth_token' , 'total', 'tem_pedido', 'ticket_medio','quantidade_pedidos','ultimo_pedido','tipo', 'perfil'].join(';')
        f << "\n"
        files.each do |path|
          puts "baixando #{path}"
          dir.files.get(path) do |chunk, remaining, total|
            f.write chunk
          end
          puts "arquivo concluido."
        end
      end

      # upload
      MarketingReports::S3Uploader.new('allin').copy_file('base_atualizada.csv')

    rescue => e
      puts e
    end
  end


end
