CREATE TABLE hotels (
    hotel_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    UNIQUE (name, city)
);

CREATE TABLE rooms (
    room_id BIGSERIAL PRIMARY KEY,
    hotel_id BIGINT NOT NULL REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    room_number VARCHAR(10) NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),
    UNIQUE (hotel_id, room_number)
);

CREATE TABLE guests (
    guest_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20)  NOT NULL UNIQUE
);

CREATE TABLE bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(room_id) ON DELETE RESTRICT,
    guest_id BIGINT NOT NULL REFERENCES guests(guest_id) ON DELETE RESTRICT,
    date_in DATE NOT NULL,
    date_out DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('active','cancelled','completed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (date_out > date_in)
);

CREATE TABLE services (
    service_id BIGSERIAL PRIMARY KEY,
    hotel_id BIGINT NOT NULL REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0), 
    UNIQUE (hotel_id, name)
);

CREATE TABLE service_history (
    usage_id BIGSERIAL PRIMARY KEY,
    service_id BIGINT NOT NULL REFERENCES services(service_id) ON DELETE RESTRICT,
    guest_id BIGINT NOT NULL REFERENCES guests(guest_id) ON DELETE RESTRICT,
    service_date DATE NOT NULL
);