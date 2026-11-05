-- Active: 1793890323710@@127.0.0.1@5432@hotels_db

-- 1) bookings.discount_percent — скидка на бронь, в процентах.
--    Необязательное поле: NULL = скидка не предусмотрена/не оформлялась,
--    0 = скидка оформлена, но нулевая (пограничное значение).
-- 2) bookings.comment — необязательная пометка оператора (причина отмены и т.п.).
ALTER TABLE bookings
    ADD COLUMN discount_percent NUMERIC(5,2)
        CHECK (discount_percent BETWEEN 0 AND 100),
    ADD COLUMN comment VARCHAR(255);

-- 3) service_history.quantity — сколько единиц услуги оказано за раз
--    (например, 3 завтрака). Без него нельзя корректно считать выручку от услуг.
--    DEFAULT 1 => все старые строки автоматически получают quantity = 1.
ALTER TABLE service_history
    ADD COLUMN quantity INT NOT NULL DEFAULT 1
        CHECK (quantity > 0);