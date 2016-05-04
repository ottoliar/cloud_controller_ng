require 'spec_helper'
require 'presenters/v3/route_mapping_presenter'
require 'messages/route_mappings_list_message'

module VCAP::CloudController
  describe RouteMappingPresenter do
    subject(:presenter) { described_class.new(route_mapping) }

    let(:route_mapping) do
      RouteMappingModel.make(
        app:          app,
        route:        route,
        process_type: process.type,
        created_at:   Time.at(1),
        updated_at:   Time.at(2),
      )
    end
    let(:app) { AppModel.make }
    let(:process) { App.make(space: app.space, app_guid: app.guid, type: 'some-type') }
    let(:route) { Route.make(space: app.space) }

    describe '#to_hash' do
      it 'matches #to_json' do
        hash = presenter.to_hash
        json = MultiJson.load(presenter.to_json)
        expect(hash.deep_stringify_keys).to eq(json)
        expect(hash).to eq(json.deep_symbolize_keys)
      end
    end

    describe '#to_json' do
      let(:result) { MultiJson.load(presenter.to_json) }

      it 'presents the route_mapping as json' do
        expect(result['guid']).to eq(route_mapping.guid)
        expect(result['created_at']).to eq('1970-01-01T00:00:01Z')
        expect(result['updated_at']).to eq('1970-01-01T00:00:02Z')
        expect(result['links']).to include('self')
        expect(result['links']).to include('app')
        expect(result['links']).to include('route')
        expect(result['links']).to include('process')
      end

      context 'links' do
        it 'includes correct link hrefs' do
          expect(result['links']['self']['href']).to eq("/v3/route_mappings/#{route_mapping.guid}")
          expect(result['links']['app']['href']).to eq("/v3/apps/#{app.guid}")
          expect(result['links']['route']['href']).to eq("/v2/routes/#{route_mapping.route.guid}")
          expect(result['links']['process']['href']).to eq("/v3/apps/#{app.guid}/processes/some-type")
        end

        context 'when the process is gone' do
          let(:route_mapping) do
            RouteMappingModel.make(process_type: nil)
          end

          it 'has a null link for process' do
            expect(result['links']['process']).to be_nil
          end
        end
      end
    end
  end
end