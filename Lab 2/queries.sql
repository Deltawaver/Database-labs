
-- ЧАСТЬ 2.1. Многотабличные запросы (JOIN)

-- 2.1.1. Подробная информация о бронях: гость + номер + отель + стоимость
SELECT b.booking_id,
       g.name                      AS guest,
       h.name                      AS hotel,
       h.city,
       r.room_number,
       b.date_in,
       b.date_out,
       (b.date_out - b.date_in)    AS nights,
       b.status,
       ROUND(r.price * (b.date_out - b.date_in)
             * (1 - COALESCE(b.discount_percent, 0) / 100), 2) AS total_cost
FROM bookings b
JOIN guests g ON g.guest_id = b.guest_id
JOIN rooms  r ON r.room_id  = b.room_id
JOIN hotels h ON h.hotel_id = r.hotel_id
ORDER BY b.date_in, b.booking_id;


-- 2.1.2. Отели и номера, у которых нет ни одной брони (LEFT JOIN + IS NULL).
--        Отель без номеров тоже попадёт в результат (COALESCE подставляет текст).
SELECT h.name  AS hotel,
       h.city,
       COALESCE(r.room_number, '— номеров нет —') AS room_number,
       r.price
FROM hotels h
LEFT JOIN rooms    r ON r.hotel_id = h.hotel_id
LEFT JOIN bookings b ON b.room_id  = r.room_id
WHERE b.booking_id IS NULL
ORDER BY h.name, r.room_number;


-- 2.1.3. Активные брони дорогих номеров (от 6000 за ночь) на 4 ночи и более
SELECT b.booking_id, g.name AS guest, h.name AS hotel, h.city,
       r.room_number, r.price AS price_per_night,
       b.date_in, (b.date_out - b.date_in) AS nights
FROM bookings b
JOIN guests g ON g.guest_id = b.guest_id
JOIN rooms  r ON r.room_id  = b.room_id
JOIN hotels h ON h.hotel_id = r.hotel_id
WHERE b.status = 'active'
  AND r.price >= 6000
  AND (b.date_out - b.date_in) >= 4
ORDER BY r.price DESC;



-- ЧАСТЬ 2.2. Агрегация и группировка

-- 2.2.1. Показатели по отелям: брони, отмены, выручка, длительность проживания.
--        LEFT JOIN, чтобы отели без броней остались с нулями.
SELECT h.name AS hotel,
       h.city,
       COUNT(b.booking_id)                                        AS bookings_total,
       COUNT(b.booking_id) FILTER (WHERE b.status = 'cancelled')  AS cancelled,
       COALESCE(ROUND(SUM(r.price * (b.date_out - b.date_in)
            * (1 - COALESCE(b.discount_percent, 0) / 100)) FILTER (WHERE b.status <> 'cancelled'), 2), 0) AS stay_revenue,
       ROUND(AVG(b.date_out - b.date_in), 1)                      AS avg_nights,
       MAX(b.date_out - b.date_in)                                AS max_nights
FROM hotels h
LEFT JOIN rooms    r ON r.hotel_id = h.hotel_id
LEFT JOIN bookings b ON b.room_id  = r.room_id
GROUP BY h.hotel_id, h.name, h.city
ORDER BY stay_revenue DESC;


-- 2.2.2. Ценные клиенты: не менее 2 состоявшихся/активных броней
--        и суммарные траты на проживание от 30 000 (фильтр групп через HAVING)
SELECT g.name AS guest,
       COUNT(*)                                   AS bookings_cnt,
       SUM(b.date_out - b.date_in)                AS total_nights,
       ROUND(AVG(b.date_out - b.date_in), 1)      AS avg_nights,
       ROUND(
        SUM(r.price * (b.date_out - b.date_in)
        * (1 - COALESCE(b.discount_percent, 0) / 100)), 2) AS total_spent
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id
JOIN rooms    r ON r.room_id  = b.room_id
WHERE b.status <> 'cancelled'
GROUP BY g.guest_id, g.name
HAVING COUNT(*) >= 2
   AND SUM(r.price * (b.date_out - b.date_in)
           * (1 - COALESCE(b.discount_percent, 0) / 100)) >= 30000
ORDER BY total_spent DESC;

-- 2.2.3. Сравнение месяцев: загрузка, доля отмен, выручка, средняя цена номера
SELECT to_char(b.date_in, 'YYYY-MM')                                   AS month,
       COUNT(*)                                                        AS bookings_total,
       COUNT(*) FILTER (WHERE b.status = 'cancelled')                  AS cancelled,
       ROUND(100.0 * COUNT(*) FILTER (WHERE b.status = 'cancelled')
             / COUNT(*), 1)                                            AS cancel_pct,
       COALESCE(ROUND(SUM(r.price * (b.date_out - b.date_in)
                    * (1 - COALESCE(b.discount_percent, 0) / 100))
                FILTER (WHERE b.status <> 'cancelled'), 2), 0)             AS revenue,
       ROUND(AVG(r.price), 0)                                          AS avg_room_price
FROM bookings b
JOIN rooms r ON r.room_id = b.room_id
GROUP BY to_char(b.date_in, 'YYYY-MM')
ORDER BY month;

-- ЧАСТЬ 3. Подзапросы
-- 3.1. Номера, цена которых выше средней по их отелю
--      (средняя считается во вложенной выборке по группам "отель")
SELECT h.name AS hotel, r.room_number, r.price,
       ROUND(a.avg_price, 2)           AS hotel_avg_price,
       ROUND(r.price - a.avg_price, 2) AS above_avg
FROM rooms r
JOIN hotels h ON h.hotel_id = r.hotel_id
JOIN (SELECT hotel_id, AVG(price) AS avg_price
      FROM rooms
      GROUP BY hotel_id) a ON a.hotel_id = r.hotel_id
WHERE r.price > a.avg_price
ORDER BY h.name, r.price DESC;


-- 3.2. EXISTS: гости, отменявшие бронь в номере дороже 5000 за ночь
SELECT g.guest_id, g.name, g.email
FROM guests g
WHERE EXISTS (SELECT 1
              FROM bookings b
              JOIN rooms r ON r.room_id = b.room_id
              WHERE b.guest_id = g.guest_id
                AND b.status = 'cancelled'
                AND r.price > 5000)
ORDER BY g.name;


-- 3.3. NOT EXISTS: услуги, которые ни разу не заказывали
--      (кандидаты на пересмотр цены/продвижение или вывод из прайса)
SELECT s.service_id, h.name AS hotel, s.name AS service, s.price
FROM services s
JOIN hotels h ON h.hotel_id = s.hotel_id
WHERE NOT EXISTS (SELECT 1
                  FROM service_history sh
                  WHERE sh.service_id = s.service_id)
ORDER BY h.name, s.name;


-- 3.4. Коррелированный подзапрос: брони, которые длиннее СРЕДНЕГО
--      срока проживания этого же гостя (внутренний запрос зависит от b.guest_id)
SELECT g.name AS guest, h.name AS hotel, b.booking_id, b.date_in,
       (b.date_out - b.date_in) AS nights,
       (SELECT ROUND(AVG(b2.date_out - b2.date_in), 1)
        FROM bookings b2
        WHERE b2.guest_id = b.guest_id
          AND b2.status <> 'cancelled') AS guest_avg_nights
FROM bookings b
JOIN guests g ON g.guest_id = b.guest_id
JOIN rooms  r ON r.room_id  = b.room_id
JOIN hotels h ON h.hotel_id = r.hotel_id
WHERE b.status <> 'cancelled'
  AND (b.date_out - b.date_in) >
      (SELECT AVG(b2.date_out - b2.date_in)
       FROM bookings b2
       WHERE b2.guest_id = b.guest_id
         AND b2.status <> 'cancelled')
ORDER BY g.name, b.date_in;


-- ЧАСТЬ 4. Комплексный отчёт (CTE)
-- Вопрос руководителя: "Какие отели приносят больше всего выручки,
-- какую долю в ней занимают услуги и где есть потенциал допродаж?"

WITH
-- Шаг 1. Промежуточные показатели (уровень отдельных операций)
stay_cost AS (            -- стоимость каждой неотменённой брони
    SELECT r.hotel_id,
           b.booking_id,
           (b.date_out - b.date_in) AS nights,
           r.price * (b.date_out - b.date_in)
                   * (1 - COALESCE(b.discount_percent, 0) / 100) AS cost
    FROM bookings b
    JOIN rooms r ON r.room_id = b.room_id
    WHERE b.status <> 'cancelled'
),
service_cost AS (         -- стоимость каждого факта оказания услуги
    SELECT s.hotel_id,
           sh.usage_id,
           s.price * sh.quantity AS cost
    FROM service_history sh
    JOIN services s ON s.service_id = sh.service_id
),
-- Шаг 2. Агрегация по отелям
stay_by_hotel AS (
    SELECT hotel_id,
           COUNT(*)    AS bookings_cnt,
           SUM(nights) AS nights,
           SUM(cost)   AS stay_revenue
    FROM stay_cost
    GROUP BY hotel_id
),
service_by_hotel AS (
    SELECT hotel_id,
           COUNT(*)  AS usage_cnt,
           SUM(cost) AS service_revenue
    FROM service_cost
    GROUP BY hotel_id
),
-- Шаг 3. Объединение: все отели, пропуски -> нули
report AS (
    SELECT h.hotel_id, h.name, h.city,
           COALESCE(st.bookings_cnt, 0)    AS bookings_cnt,
           COALESCE(st.nights, 0)          AS nights,
           COALESCE(st.stay_revenue, 0)    AS stay_revenue,
           COALESCE(sv.usage_cnt, 0)       AS usage_cnt,
           COALESCE(sv.service_revenue, 0) AS service_revenue,
           COALESCE(st.stay_revenue, 0) + COALESCE(sv.service_revenue, 0) AS total_revenue
    FROM hotels h
    LEFT JOIN stay_by_hotel    st ON st.hotel_id = h.hotel_id
    LEFT JOIN service_by_hotel sv ON sv.hotel_id = h.hotel_id
)
-- Шаг 4. Итоговый отчёт: доли, рейтинг, вывод
SELECT RANK() OVER (ORDER BY total_revenue DESC)                  AS revenue_rank,
       name AS hotel,
       city,
       bookings_cnt,
       nights,
       ROUND(stay_revenue, 2)                                     AS stay_revenue,
       ROUND(service_revenue, 2)                                  AS service_revenue,
       ROUND(total_revenue, 2)                                    AS total_revenue,
       ROUND(100.0 * service_revenue / NULLIF(total_revenue, 0), 1) AS service_share_pct,
       ROUND(100.0 * total_revenue / NULLIF(SUM(total_revenue) OVER (), 0), 1) AS chain_share_pct,
       CASE
           WHEN total_revenue = 0                                   THEN 'Нет выручки'
           WHEN usage_cnt = 0                                       THEN 'Услуги не продаются'
           WHEN 100.0 * service_revenue / total_revenue < 5         THEN 'Низкая доля услуг: потенциал допродаж'
           ELSE 'Доля услуг в норме'
       END AS comment
FROM report
ORDER BY revenue_rank, name;