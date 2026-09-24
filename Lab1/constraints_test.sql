-- ============================================================
-- constraints_test.sql
-- Проверка ограничений целостности БД "Система бронирования гостиниц"
-- Каждый блок содержит НЕКОРРЕКТНУЮ операцию, которая ДОЛЖНА
-- быть отклонена PostgreSQL. Рядом указано, какое ограничение
-- срабатывает.
--
-- ВАЖНО: перед запуском убедись, что data.sql уже залит.
-- ============================================================


-- ------------------------------------------------------------
-- 1. UNIQUE: email гостя должен быть уникальным
-- Ожидаемая ошибка: duplicate key value violates unique constraint "guests_email_key"
-- ------------------------------------------------------------
INSERT INTO guests (name, email, phone) VALUES
('Дубликат', 'ivanov@mail.ru', '+79990000001');


-- ------------------------------------------------------------
-- 2. UNIQUE: телефон гостя должен быть уникальным
-- Ожидаемая ошибка: duplicate key value violates unique constraint "guests_phone_key"
-- ------------------------------------------------------------
INSERT INTO guests (name, email, phone) VALUES
('Дубликат', 'newmail@mail.ru', '+79161234567');


-- ------------------------------------------------------------
-- 3. CHECK: цена номера должна быть > 0
-- Ожидаемая ошибка: new row for relation "rooms" violates check constraint "rooms_price_check"
-- ------------------------------------------------------------
INSERT INTO rooms (hotel_id, room_number, price) VALUES
(1, '999', -100.00);


-- ------------------------------------------------------------
-- 4. CHECK: цена услуги должна быть >= 0
-- Ожидаемая ошибка: new row for relation "services" violates check constraint "services_price_check"
-- ------------------------------------------------------------
INSERT INTO services (hotel_id, name, price) VALUES
(1, 'Бесплатный сыр', -50.00);


-- ------------------------------------------------------------
-- 5. CHECK: date_out должна быть больше date_in
-- Ожидаемая ошибка: new row for relation "bookings" violates check constraint "bookings_check"
-- ------------------------------------------------------------
INSERT INTO bookings (room_id, guest_id, date_in, date_out, status) VALUES
(1, 1, '2026-06-10', '2026-06-05', 'active');


-- ------------------------------------------------------------
-- 6. CHECK: статус брони — только из допустимого списка
-- Ожидаемая ошибка: new row for relation "bookings" violates check constraint "bookings_status_check"
-- ------------------------------------------------------------
INSERT INTO bookings (room_id, guest_id, date_in, date_out, status) VALUES
(1, 1, '2026-06-10', '2026-06-15', 'unknown');


-- ------------------------------------------------------------
-- 7. UNIQUE (составное): в одном отеле не может быть двух
--    услуг с одинаковым названием
-- Ожидаемая ошибка: duplicate key value violates unique constraint "services_hotel_id_name_key"
-- ------------------------------------------------------------
INSERT INTO services (hotel_id, name, price) VALUES
(1, 'Завтрак', 900.00);


-- ------------------------------------------------------------
-- 8. UNIQUE (составное): в одном отеле не может быть двух
--    номеров с одинаковым номером комнаты
-- Ожидаемая ошибка: duplicate key value violates unique constraint "rooms_hotel_id_room_number_key"
-- ------------------------------------------------------------
INSERT INTO rooms (hotel_id, room_number, price) VALUES
(1, '101', 7500.00);


-- ------------------------------------------------------------
-- 9. FOREIGN KEY: бронь не может ссылаться на несуществующего гостя
-- Ожидаемая ошибка: insert or update on table "bookings" violates foreign key constraint "bookings_guest_id_fkey"
-- ------------------------------------------------------------
INSERT INTO bookings (room_id, guest_id, date_in, date_out, status) VALUES
(1, 9999, '2026-06-10', '2026-06-15', 'active');


-- ------------------------------------------------------------
-- 10. FOREIGN KEY: бронь не может ссылаться на несуществующий номер
-- Ожидаемая ошибка: insert or update on table "bookings" violates foreign key constraint "bookings_room_id_fkey"
-- ------------------------------------------------------------
INSERT INTO bookings (room_id, guest_id, date_in, date_out, status) VALUES
(9999, 1, '2026-06-10', '2026-06-15', 'active');


-- ------------------------------------------------------------
-- 11. NOT NULL: имя отеля обязательно
-- Ожидаемая ошибка: null value in column "name" of relation "hotels" violates not-null constraint
-- ------------------------------------------------------------
INSERT INTO hotels (name, city) VALUES
(NULL, 'Тверь');


-- ------------------------------------------------------------
-- 12. ON DELETE RESTRICT: нельзя удалить гостя, у которого есть брони
-- Ожидаемая ошибка: update or delete on table "guests" violates foreign key constraint "bookings_guest_id_fkey"
-- ------------------------------------------------------------
DELETE FROM guests WHERE guest_id = 1;


-- ------------------------------------------------------------
-- 13. ON DELETE RESTRICT: нельзя удалить номер, на который есть брони
-- Ожидаемая ошибка: update or delete on table "rooms" violates foreign key constraint "bookings_room_id_fkey"
-- ------------------------------------------------------------
DELETE FROM rooms WHERE room_id = 1;


-- ------------------------------------------------------------
-- 14. ON DELETE RESTRICT: нельзя удалить услугу, которая
--     фигурирует в истории оказания услуг
-- Ожидаемая ошибка: update or delete on table "services" violates foreign key constraint "service_history_service_id_fkey"
-- ------------------------------------------------------------
DELETE FROM services WHERE service_id = 1;