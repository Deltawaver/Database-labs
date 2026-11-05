BEGIN;

-- ------------------------------------------------------------
-- 1. INSERT: новая сущность (отель) и связанные записи
-- ------------------------------------------------------------
INSERT INTO hotels (name, city) VALUES ('Золотой Берег', 'Анапа');

INSERT INTO rooms (hotel_id, room_number, price)
SELECT h.hotel_id, v.num, v.price
FROM hotels h
CROSS JOIN (VALUES ('101', 4200.00), ('102', 5100.00)) AS v(num, price)
WHERE h.name = 'Золотой Берег';

INSERT INTO services (hotel_id, name, price)
SELECT hotel_id, 'Завтрак', 750.00 FROM hotels WHERE name = 'Золотой Берег';

INSERT INTO guests (name, email, phone)
VALUES ('Лебедев Николай', 'lebedev@mail.ru', '+79777890123');

INSERT INTO bookings (room_id, guest_id, date_in, date_out, status, discount_percent, comment)
SELECT r.room_id, g.guest_id, DATE '2026-08-10', DATE '2026-08-14', 'active', NULL, 'Первое бронирование'
FROM rooms r
JOIN hotels h ON h.hotel_id = r.hotel_id
CROSS JOIN guests g
WHERE h.name = 'Золотой Берег' AND r.room_number = '101' AND g.email = 'lebedev@mail.ru';

-- ------------------------------------------------------------
-- 2. UPDATE: изменение состояния одной брони (active -> completed)
-- ------------------------------------------------------------
UPDATE bookings
SET status = 'completed', comment = 'Гость выехал, проживание закрыто'
WHERE booking_id = 3 AND status = 'active';

-- ------------------------------------------------------------
-- 3. Массовый UPDATE по содержательному условию:
--    все "зависшие" активные брони, срок которых истёк до 01.06.2026, закрываем.
--    (в боевой системе вместо даты было бы CURRENT_DATE)
-- ------------------------------------------------------------
UPDATE bookings
SET status = 'completed'
WHERE status = 'active'
  AND date_out < DATE '2026-06-01';

-- ------------------------------------------------------------
-- 4. DELETE с учётом ограничений целостности
-- ------------------------------------------------------------
-- 4a. Попытка удалить гостя с бронями: запрещено (ON DELETE RESTRICT).
DO $$
BEGIN
    DELETE FROM guests WHERE guest_id = 1;
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'Удаление гостя 1 отклонено: на него ссылаются брони и услуги (RESTRICT)';
END $$;

-- 4b. Корректное удаление: сначала зависимые записи, потом сам гость.
DELETE FROM service_history
WHERE guest_id = (SELECT guest_id FROM guests WHERE email = 'lebedev@mail.ru');

DELETE FROM bookings
WHERE guest_id = (SELECT guest_id FROM guests WHERE email = 'lebedev@mail.ru');

DELETE FROM guests WHERE email = 'lebedev@mail.ru';

COMMIT;

-- ------------------------------------------------------------
-- 5. ROLLBACK: изменения внутри транзакции отменяются
-- ------------------------------------------------------------
BEGIN;

SELECT status, COUNT(*) AS cnt FROM bookings GROUP BY status ORDER BY status;  -- до

UPDATE bookings SET status = 'cancelled'
WHERE status = 'active' AND date_in >= DATE '2026-07-01';

SELECT status, COUNT(*) AS cnt FROM bookings GROUP BY status ORDER BY status;  -- внутри транзакции: cancelled стало больше

ROLLBACK;

SELECT status, COUNT(*) AS cnt FROM bookings GROUP BY status ORDER BY status;  -- после: как "до"