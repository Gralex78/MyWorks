
-- �������� ������ --

-- ������� 1 --
-- � ����� ������� ������ ������ ���������? 

select city
from airports a 
group by city
having count(airport_code) > 1





-- ������� 2 --
-- � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? 
-- (���������)

select a.airport_name 
from airports a
join flights f on a.airport_code = f.departure_airport
join aircrafts a2 using(aircraft_code)
where a2."range" = (select max("range") 
				    from aircrafts a)
group by a.airport_name





-- ������� 3 --
-- ������� 10 ������ � ������������ �������� �������� ������ 
-- (�������� LIMIT)

select t.flight_no, t.delay
from (
	select (actual_departure - scheduled_departure) as delay, flight_no 
	from flights f) t
where t.delay is not null
order by t.delay desc
limit 10





-- ������� 4 --
-- ���� �� �����, �� ������� �� ���� �������� ���������� ������? 
-- (������ ��� JOIN)

select b.book_ref, t.ticket_no, bp.boarding_no 
from bookings b
left join tickets t using(book_ref)
left join ticket_flights tf using(ticket_no)
left join boarding_passes bp using(ticket_no)
where boarding_no is null
group by b.book_ref, t.ticket_no, bp.boarding_no
order by b.book_ref 

-- �����: ��, ����





-- ������� 5 --
-- ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
-- �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
-- (������� �������, ���������� ��� cte)

with cte_1 as ( 
	select flight_id, aircraft_code, actual_departure, departure_airport 
	from flights),
cte_2 as (
	select flight_id, count(seat_no) as quantity_seats_use
	from boarding_passes
	group by flight_id),
cte_3 as (
	select aircraft_code, count(seat_no) as quantity_seats_total  
 	from seats
 	group by aircraft_code),
cte_4 as (
	select airport_name, airport_code 
	from airports a3)
select c1.flight_id, c3.quantity_seats_total, c2.quantity_seats_use, (c3.quantity_seats_total - c2.quantity_seats_use) as vocant_seats,
	((c3.quantity_seats_total - c2.quantity_seats_use) * 100 / c3.quantity_seats_total) as "proportion, %", c4.airport_name, 
	date_trunc('day', c1.actual_departure) as day_departure,
	sum(c2.quantity_seats_use) over (partition by c4.airport_name, date_trunc('day', c1.actual_departure) order by c4.airport_name, c1.actual_departure)
from cte_1 c1
join cte_2 c2 on c2.flight_id = c1.flight_id
join cte_3 c3 on c3.aircraft_code = c1.aircraft_code
join cte_4 c4 on c1.departure_airport = c4.airport_code
group by c1.flight_id, c4.airport_name, c2.quantity_seats_use, c3.quantity_seats_total, c1.actual_departure
order by c4.airport_name, day_departure

-- ������� flights �������� ������� �� ���������� ���� � ��������������� ��������� �� ������� seats, 
-- ����� �������� ������� �� ���������� ����, �� ������� ������ ���������� ������ �� ������� boarding_passes,
-- � �������� select, ��������� �������� (vocant_seats), ������ ������� � ������� ���������� ��������� ����,
-- ����� � ������� "proportion, %" ������ ��������� ��������� ���� � ������ ���������� ���� � ���������,
-- � ������� ������� ������� �������� ������� sum � ����������� ���������� ���������� ���������� �� ������� ��������� �� ������ ���� 





-- ������� 6 --
-- ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. 
-- (���������, �������� ROUND)

select a.model,  
	round(t.quantity_of_bords * 100 / sum(t.quantity_of_bords) over ()) as "proportion, %"
from (
	select aircraft_code, count(aircraft_code) as quantity_of_bords  
	from flights f 
	group by aircraft_code
	order by aircraft_code) t
	join aircrafts a on t.aircraft_code = a.aircraft_code 
order by "proportion, %"

-- ����������� �������� ����� ���������� ��������� ��������� �� �����,
-- � select, ��������� �������� (proportion, %), �������� �� ��������� � ������ ���������� ���������  





-- ������� 7 --
-- ���� �� ������, � ������� ����� ��������� ������-������� �������, ��� ������-������� � ������ ��������? 
-- (CTE)

with cte_1 as ( 
	select city, airport_name, airport_code
	from airports),
cte_2 as (
	select arrival_airport, flight_id, flight_no
	from flights),
cte_3 as (
	select flight_id, fare_conditions, amount, rn  
 	from (
		select flight_id, fare_conditions, amount,
			row_number() over (partition by flight_id order by amount desc) as rn
		from ticket_flights tf
		group by flight_id, fare_conditions, amount) t
	where fare_conditions = 'Business' and rn != 1
	group by flight_id, fare_conditions, amount, rn)
select c1.city, c1.airport_name
from cte_1 c1
join cte_2 c2 on c2.arrival_airport = c1.airport_code
join cte_3 c3 on c3.flight_id = c2.flight_id

-- �����: ���, �� ���� ����� �������

-- ����������� � CTE_3 ������� ���������� ��������� ������� �� ���������,
-- � ������� where �������� ������ �� ��������� ������-�����.




-- ������� 8 --
-- ����� ������ �������� ��� ������ ������? 
-- (��������� ������������ � ����������� FROM, �������������� ��������� �������������, �������� EXCEPT)

select a.city as dep_city, b.city as arr_city
from airports a 
cross join airports b
where a.city < b.city
except
select departure_city, arrival_city 
from routes r
group by departure_city, arrival_city

-- � ������ �������, ���������� �������������, �������� ���� �������, � ������� ���� ���������,
-- �� ������ - ������, ����� �������� ���� ������ �����,
-- ������� �� ������� ������� ������ � ������� ������ ����� �������� ��� ������ ������.


create view no_direct_flights as
select a.city as dep_city, b.city as arr_city
from airports a 
cross join airports b
where a.city < b.city
except
select departure_city, arrival_city 
from routes r
group by departure_city, arrival_city

select * from no_direct_flights

create materialized view city_no_direct_flights as
select a.city as dep_city, b.city as arr_city
from airports a 
cross join airports b
where a.city < b.city
except
select departure_city, arrival_city 
from routes r
group by departure_city, arrival_city
with data

refresh materialized view city_no_direct_flights

select * from city_no_direct_flights





-- ������� 9 --
-- ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ��������� � ���������, ������������� ��� ����� *
-- (�������� RADIANS ��� ������������� sind/cosd, CASE)

select t.departure_airport_name, t.arrival_airport_name, 
	round(acos(sin(radians(t.latitude)) * sin(radians(a.latitude)) + cos(radians(t.latitude)) * cos(radians(a.latitude)) * 
		cos(radians(t.longitude) - radians(a.longitude))) * 6371) as "distance, km",
	a2.model, a2."range",
		case
			when round(acos(sin(radians(t.latitude)) * sin(radians(a.latitude)) + cos(radians(t.latitude)) * cos(radians(a.latitude)) * 
				cos(radians(t.longitude) - radians(a.longitude))) * 6371) < a2."range" then '� �������� �����'
			when round(acos(sin(radians(t.latitude)) * sin(radians(a.latitude)) + cos(radians(t.latitude)) * cos(radians(a.latitude)) * 
				cos(radians(t.longitude) - radians(a.longitude))) * 6371) = a2."range" then '��������'
			else '�� ���������'
		end
from (
	select r.flight_no, r.departure_airport_name, r.departure_airport, a.longitude, a.latitude, r.arrival_airport_name, r.arrival_airport 
	from routes r
	join airports a on a.airport_code = r.departure_airport) t
	join airports a on a.airport_code = t.arrival_airport
	join flights f on t.flight_no = f.flight_no 
	join aircrafts a2 on f.aircraft_code = a2.aircraft_code
where departure_airport_name < arrival_airport_name
group by t.departure_airport_name, t.longitude, t.latitude, t.arrival_airport_name, a.longitude, a.latitude, a2.model, a2."range"


-- ����������� �������� ������ ������� routes ������������ ���������� ����������� �� ������� airports,
-- ����� � ������� join �������� ������ ����������� ���������� �������� �� ��� �� ������� airports,
-- ����� � ������� join ������� ������ ����� ���������� �� ������� flights � ������ ��������� 
-- � �� ������������� ����������� ��������� �� ������� aircrafts,
-- � �������� select �������� "distance, km" ������ ���������� ����� �����������,
-- � ������� ��������� case ��������� � ���������� ������������ ���������� ��������� � ���������, ������������� ��� ����� 






