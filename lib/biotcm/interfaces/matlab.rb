# Interface to MATLAB
module BioTCM::Interfaces::Matlab
  include BioTCM::Interfaces::Interface

  # Run MATLAB script
  # @param script_path [String] path to the script
  # @param matlab_path [String] path to matlab
  def run_matlab_script(script_path, matlab_path: 'matlab')
    raise ArgumentError, 'A valid MATLAB script required' unless /\.m$/i =~ script_path
    system("#{matlab_path} -nojvm -r 'run #{script_path}; exit'")
  end

  # Evaluate MATLAB script
  # @param matlab_path [String] path to matlab
  # @see Interface#render_template
  def evaluate_matlab_script(template_path, context, matlab_path: 'matlab')
    raise ArgumentError, 'A valid MATLAB template script required' unless /\.m\.erb$/i =~ template_path

    # Make filename valid for MATLAB
    script = render_template(template_path, context)
    script_path = File.expand_path(
      File.basename(script.path).gsub(/-|\[|\]/, '_'),
      File.dirname(script.path)
    )
    new_script = File.open(script_path, 'w')
    new_script.write script.read
    new_script.close # write to file from buffer
    run_matlab_script(script_path, matlab_path: matlab_path)
    script.close # close the rendered file
  end
end
