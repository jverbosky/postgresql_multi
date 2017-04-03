select *
from details
join numbers on details.id = numbers.details_id
join quotes on details.id = quotes.details_id