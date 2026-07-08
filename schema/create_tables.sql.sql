CREATE TABLE "customers" (
  "id" bigserial PRIMARY KEY,
  "name" varchar NOT NULL,
  "email" varchar UNIQUE NOT NULL,
  "phone" VARCHAR NOT NULL
);

CREATE TABLE "customer_addresses" (
  "id" bigserial PRIMARY KEY,
  "customer_id" bigint NOT NULL,
  "address" varchar not null,
  "type_address" varchar not null check (type_address in ('HOME', 'WORK', 'SHIPPING')),
  
  constraint fk_adress foreign key (customer_id) references customers (id) on delete CASCADE
);

CREATE TABLE "categories" (
  "id" bigserial PRIMARY KEY,
  "category" varchar NOT null CHECK (category IN ('ELECTRONICS', 'HOME', 'GARDEN', 'FOOD', 'AUTO')) 
);

CREATE TABLE "products" (
  "id" bigserial PRIMARY KEY,
  "category_id" bigint NOT NULL,
  "name" varchar NOT NULL,
  sku varchar not null unique,
  "description" varchar,
  "price" numeric(10,2) NOT NULL CHECK (price>0),
  "stock" integer NOT NULL CHECK (stock>=0),
  
  constraint fk_category foreign key (category_id) references categories (id)
);


CREATE TABLE "orders" (
  "id" bigserial PRIMARY KEY,
  "customer_id" bigint NOT NULL,
  "order_date" date NOT NULL,
  "status" varchar NOT NULL CHECK (status IN ('PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
  total_amount numeric(10,2) not null check (total_amount>0),
  
  constraint fk_customer foreign key (customer_id) references customers (id)

);

create table order_items (
  id bigserial primary key,
  order_id bigint not null,
  product_id bigint not null,
  quantity integer not null check (quantity>0),
  unit_price numeric(10,2) not null check (unit_price>0),
  
  constraint fk_ord foreign key (order_id) references orders (id),
  constraint fk_produc foreign key (product_id) references products (id) 
);


CREATE TABLE "payments" (
  "id" bigserial PRIMARY KEY,
  "order_id" bigint NOT null unique,
  "amount" NUMERIC(10,2) NOT NULL CHECK (amount>0),
  "payment_method" varchar NOT null check (payment_method in ('CREDIT CARD', 'PAYPAL', 'BANK TRANSFER')),
  payment_date date not null,
  
  constraint fk_order_pay foreign key (order_id) references orders (id)
);

CREATE TABLE "shipments" (
  "id" bigserial PRIMARY KEY,
  "order_id" bigint NOT null unique,
  "shipment_address" varchar NOT NULL,
  "shipment_date" date NOT NULL,
  "shipment_status" varchar NOT null check (shipment_status in ('PENDING', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'RETURNED')),
  tracking_number varchar,
  
  constraint fk_order_shipm foreign key (order_id) references orders (id)
);

CREATE TABLE "returns" (
  "id" bigserial PRIMARY KEY,
  "order_id" bigint NOT NULL,
  "return_date" date NOT NULL,
  "return_status" varchar NOT null check (return_status in ('RECEIVED', 'APPROVED', 'IN TRANSIT', 'COMPLETED')),
  "return_amount" NUMERIC(10,2) NOT null check (return_amount >=0),
  
  constraint fk_order_ret foreign key (order_id) references orders (id)
);

CREATE TABLE "return_items" (
  "id" bigserial PRIMARY KEY,
  "return_id" bigint NOT NULL,
  "product_id" bigint NOT null,
  quantity integer not null check (quantity>0),
  
  constraint fk_ret foreign key (return_id) references returns (id),
  constraint fk_prod foreign key (product_id) references products (id)
);
