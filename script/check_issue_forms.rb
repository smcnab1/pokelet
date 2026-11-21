# frozen_string_literal: true

require 'yaml'

root = File.expand_path('..', __dir__)
templates = File.join(root, '.github', 'ISSUE_TEMPLATE')
forms = {
  'bug_report.yml' => { label: 'bug', required: %w[behaviour steps expected] },
  'feature_request.yml' => { label: 'enhancement', required: %w[proposal use-case] }
}
files = Dir.children(templates).sort
abort 'Expected exactly two issue forms and config.yml' unless files == (forms.keys + ['config.yml']).sort

forms.each do |filename, policy|
  form = YAML.safe_load(File.read(File.join(templates, filename)))
  abort "#{filename}: missing name or description" if %w[name description].any? { |key| form[key].to_s.empty? }
  abort "#{filename}: unexpected labels" unless form.fetch('labels') == [policy.fetch(:label)]

  fields = form.fetch('body').reject { |field| field.fetch('type') == 'markdown' }
  ids = fields.map { |field| field.fetch('id') }
  labels = fields.map { |field| field.fetch('attributes').fetch('label') }
  abort "#{filename}: invalid field IDs" unless ids == ids.uniq && ids.all? { |id| /\A[\w-]+\z/.match?(id) }
  abort "#{filename}: duplicate field labels" unless labels == labels.uniq
  abort "#{filename}: unsupported input type" unless fields.all? { |field| %w[input textarea].include?(field.fetch('type')) }

  required = fields.select { |field| field.dig('validations', 'required') == true }
  abort "#{filename}: missing required fields" unless required.map { |field| field.fetch('id') } == policy.fetch(:required)

  feedback = File.read(File.join(root, 'Pokelet', 'Models', 'GitHubFeedback.swift'))
  readme = File.read(File.join(root, 'README.md'))
  abort "#{filename}: missing app or README link" unless feedback.include?(filename) && readme.include?("template=#{filename}")

  next unless filename == 'bug_report.yml'

  environment = fields.find { |field| field['id'] == 'environment' }
  abort 'Missing editable environment prefill field' unless environment&.fetch('type') == 'textarea' &&
                                                             feedback.include?('name: "environment"')
  warning = form.fetch('body').find { |field| field['type'] == 'markdown' }
  abort 'Missing private reporting route' unless warning&.dig('attributes', 'value')&.include?('/security/advisories/new')
end

config = YAML.safe_load(File.read(File.join(templates, 'config.yml')))
abort 'Missing security policy from chooser' unless config.fetch('contact_links').any? { |link| link.fetch('url').end_with?('/security/policy') }
puts 'GitHub issue forms, field mapping, labels and feedback links passed.'
