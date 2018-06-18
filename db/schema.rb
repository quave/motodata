# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 50) do

  create_table "circuits", force: :cascade do |t|
    t.string "name", null: false
    t.string "long_name"
    t.string "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_circuits_on_name", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "number", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "circuit_id"
    t.index ["circuit_id"], name: "index_events_on_circuit_id"
    t.index ["year"], name: "index_events_on_year"
  end

  create_table "laps", force: :cascade do |t|
    t.integer "sequence", null: false
    t.integer "position", default: 0, null: false
    t.integer "time"
    t.integer "t1"
    t.integer "t2"
    t.integer "t3"
    t.integer "t4"
    t.float "speed"
    t.boolean "finished"
    t.boolean "pit"
    t.string "session", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "rider_id"
    t.integer "event_id"
    t.index ["event_id", "rider_id", "session"], name: "index_laps_on_event_id_and_rider_id_and_session"
    t.index ["event_id"], name: "index_laps_on_event_id"
    t.index ["rider_id"], name: "index_laps_on_rider_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "country"
    t.string "birthplace"
    t.string "info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name", unique: true
  end

  create_table "riders", force: :cascade do |t|
    t.integer "number", null: false
    t.string "team", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "person_id"
    t.string "category"
    t.index ["person_id"], name: "index_riders_on_person_id"
  end

end
