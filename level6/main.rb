require "json"
require "date"

class Rental
  @@instance_collector = []

  def initialize(rental, car)
    @car = car
    @id = rental["id"]
    @start_date = DateTime.parse(rental["start_date"]).to_date
    @end_date = DateTime.parse(rental["end_date"]).to_date
    @distance = rental["distance"]
    @is_deductible = rental["deductible_reduction"]
    @deductible_reduction = get_deductible_fee()
    @total_profit = compute_total_price()
    save_all_fees()

    @@instance_collector << self
  end

  def save_all_fees()
    dedu = @deductible_reduction
    commission = @total_profit.to_f * 0.3
    
    @driver = @total_profit + dedu
    @owner = @total_profit.to_f * 0.7
    @assistance = get_rental_days() * 100
    @insurance = commission * 0.5
    @platform = commission - @assistance - @insurance
    @platform += dedu
  end

  def compute_total_price()
    days_of_rental = get_rental_days()
    reduc = 0
    
    #reduction
    for i in 1..days_of_rental
      if i > 10
        reduc += @car["price_per_day"].to_f * 0.5
      elsif i > 4
        reduc += @car["price_per_day"].to_f * 0.3
      elsif i > 1
        reduc += @car["price_per_day"].to_f * 0.1
      else
        reduc += 0
      end
    end

    price = (days_of_rental * @car['price_per_day']) - reduc
    price += @distance * @car["price_per_km"]
  end

  def generate_modification_actions()
    dedu = get_deductible_fee()
    new_profit = compute_total_price().to_f
    new_commission = new_profit * 0.3
     
    new_driver = ((new_profit + dedu) - @driver).abs
    new_owner = ((new_profit.to_f * 0.7) - @owner).abs
    new_assistance = ((get_rental_days() * 100) - @assistance).abs
    new_insurance = ((new_commission * 0.5) - @insurance).abs
    new_platform = (new_profit.to_f * 0.3) - (get_rental_days() * 100) - (new_commission * 0.5)
    new_platform += dedu
    new_platform = (new_platform - @platform).abs
    actions = []
    if (@driver - new_driver > 0)
      credit = false
    else
      credit = true
    end
    actions[0] = generate_fee_hash("driver", new_driver, credit)
    actions[1] = generate_fee_hash("owner", new_owner, !credit)
    actions[2] = generate_fee_hash("insurance", new_insurance, !credit)
    actions[3] = generate_fee_hash("assistance", new_assistance, !credit)
    actions[4] = generate_fee_hash("platform", new_platform, !credit)
    return actions
  end


  def generate_fee_hash(who, fee, is_debit)
    type = (is_debit == true) ? "debit" : "credit"
    return {"who": who, "type": type, "amount": fee.to_i}
  end
  
  def get_deductible_fee()
    if @is_deductible then return get_rental_days() * 400 end
    return 0
  end

  def get_rental_days()
    return ((@end_date - @start_date).to_i + 1)
  end

  def get_id()
    @id
  end

  def start_date=(date)
    @start_date = DateTime.parse(date).to_date
  end

  def end_date=(date)
    @end_date = DateTime.parse(date).to_date
  end

  def distance=(distance)
    @distance=(distance)
  end

  def self.all_offspring
    @@instance_collector
  end

end #of rental class

def get_car(cars, car_id)
  cars.each do |car|
    if car["id"] == car_id then return car end
  end
  return nil
end

def generate_first_contracts(data)
  cars = data["cars"]
  rentals = data["rentals"]

  price_hash = {}
  price_hash["rentals"] = []

  rentals.each do |rental|
    i = rental["id"] - 1
    car = get_car(cars, rental["car_id"])
    Rental.new(rental, car)
  end
end

def get_rental_by_id(id)
  contracts = Rental.all_offspring
  contracts.each do |c|
    if c.get_id() == id then return c end
  end
  return nil
end

def apply_rental_modifications(contracts, modif)
  result = Hash.new
  result["rental_modifications"] = Array.new
  modif.each_with_index do |m, i|
    c = get_rental_by_id(m["rental_id"])
    if m["start_date"] then c.start_date= m["start_date"] end
    if m["end_date"] then c.end_date= m["end_date"] end
    if m["distance"] then c.distance= m["distance"] end
    actions = c.generate_modification_actions()
    result["rental_modifications"][i] = {
          "id": i + 1,
          "rental_id": c.get_id(),
          "actions": actions
        }
  end
  return result
end

def print_contracts(cs)
  cs.each do |c|
    c.print_content()
  end
end

def main
  file = File.read('data.json')
  data = JSON.parse(file)

  generate_first_contracts(data)
  contracts = Rental.all_offspring
  modified_contracts = apply_rental_modifications(contracts, data["rental_modifications"])

  #change json to output_test to make difference between actual and waited results clearer
  File.open("./output_test.json","w") do |f|
    f.puts(JSON.pretty_generate(modified_contracts))
  end
end

main