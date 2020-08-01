# frozen_string_literal: true

RSpec.describe Ukemi::Moderator do
  subject { described_class.new }

  let(:pt_mock) { double("PassiveTotal") }
  let(:vt_mock) { double("VirusTotal") }
  let(:st_mock) { double("SecurityTrails") }
  let(:circl_mock) { double("CIRCL") }
  let(:dnsdb_mock) { double("DNSDB") }
  let(:otx_mock) { double("OTX") }

  before do
    allow(pt_mock).to receive(:lookup).and_return(
      [Ukemi::Record.new(data: "1.1.1.1", source: "PassiveTotal")]
    )
    allow(pt_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::PassiveTotal).to receive(:new).and_return(pt_mock)

    allow(vt_mock).to receive(:lookup).and_return(
      [Ukemi::Record.new(data: "2.2.2.2", first_seen: "2019-01-01", last_seen: "2019-01-01", source: "VirusTotal")]
    )
    allow(vt_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::VirusTotal).to receive(:new).and_return(vt_mock)

    allow(st_mock).to receive(:lookup).and_return(
      [Ukemi::Record.new(data: "2.2.2.2", first_seen: "2018-01-01", last_seen: "2018-01-01", source: "SecurityTrails")]
    )
    allow(st_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::SecurityTrails).to receive(:new).and_return(st_mock)

    allow(circl_mock).to receive(:lookup).and_return(
      [Ukemi::Record.new(data: "3.3.3.3", first_seen: "2017-01-01", last_seen: "2017-01-01", source: "CIRCL")]
    )
    allow(circl_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::CIRCL).to receive(:new).and_return(circl_mock)

    allow(dnsdb_mock).to receive(:lookup).and_return(
      []
    )
    allow(dnsdb_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::DNSDB).to receive(:new).and_return(dnsdb_mock)

    allow(otx_mock).to receive(:lookup).and_return(
      []
    )
    allow(otx_mock).to receive(:configurated?).and_return(true)
    allow(Ukemi::Services::OTX).to receive(:new).and_return(otx_mock)
  end

  describe "#lookup" do
    before do
      allow(Parallel).to receive(:processor_count).and_return(0)
    end

    it do
      results = subject.lookup("example.com")
      expect(results).to be_a(Hash)
    end

    it "is ordered by last_seen (desc)" do
      results = subject.lookup("example.com")
      first = results.keys.first
      expect(first).to eq("2.2.2.2")

      first_seen = results.dig(first, :first_seen)
      expect(first_seen).to eq("2018-01-01")

      last_seen = results.dig(first, :last_seen)
      expect(last_seen).to eq("2019-01-01")
    end

    context "when given an ordering options" do
      after do
        Ukemi.configure do |config|
          config.ordering_key = "last_seen"
          config.sort_order = "DESC"
        end
      end

      it do
        Ukemi.configure do |config|
          config.ordering_key = "last_seen"
          config.sort_order = "ASC"
        end
        results = subject.lookup("example.com")
        expect(results.keys.first).to eq("3.3.3.3")
      end

      it do
        Ukemi.configure do |config|
          config.ordering_key = "first_seen"
          config.sort_order = "DESC"
        end
        results = subject.lookup("example.com")
        expect(results.keys.first).to eq("2.2.2.2")
      end

      it do
        Ukemi.configure do |config|
          config.ordering_key = "first_seen"
          config.sort_order = "ASC"
        end
        results = subject.lookup("example.com")
        expect(results.keys.first).to eq("3.3.3.3")
      end
    end
  end
end
