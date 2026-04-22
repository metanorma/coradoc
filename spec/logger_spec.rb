# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Logger do
  describe 'constants' do
    it 'defines BADGE' do
      expect(described_class::BADGE).to eq('Coradoc')
    end

    it 'defines COLORS hash' do
      expect(described_class::COLORS).to be_a(Hash)
      expect(described_class::COLORS).to include(:error, :info, :warn, :success)
    end
  end

  describe '.error' do
    it 'logs an error message' do
      expect(Warning).to receive(:warn).with(a_string_including('ERROR').and(include('Test error')))
      described_class.error('Test error')
    end
  end

  describe '.info' do
    it 'logs an info message' do
      expect(Warning).to receive(:warn).with(a_string_including('INFO').and(include('Test info')))
      described_class.info('Test info')
    end
  end

  describe '.warn' do
    it 'logs a warning message' do
      expect(Warning).to receive(:warn).with(a_string_including('WARN').and(include('Test warning')))
      described_class.warn('Test warning')
    end
  end

  describe '.success' do
    it 'logs a success message' do
      expect(Warning).to receive(:warn).with(a_string_including('SUCCESS').and(include('Test success')))
      described_class.success('Test success')
    end
  end

  describe '#call' do
    it 'formats and outputs the message' do
      logger = described_class.new
      expect(Warning).to receive(:warn).with(a_string_including('[Coradoc]'))
      logger.call('Test message', :info)
    end
  end

  describe 'message formatting' do
    it 'includes the badge' do
      expect(Warning).to receive(:warn).with(a_string_including('[Coradoc]'))
      described_class.info('Test')
    end

    it 'includes the message type in uppercase' do
      expect(Warning).to receive(:warn).with(a_string_including('INFO'))
      described_class.info('Test')
    end

    it 'includes the message content' do
      expect(Warning).to receive(:warn).with(a_string_including('My custom message'))
      described_class.info('My custom message')
    end
  end
end
