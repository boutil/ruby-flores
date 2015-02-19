require "randomized"
require "socket"
require "rspec/stress_it"

RSpec.configure do |c|
  c.extend RSpec::StressIt
end

describe TCPServer do
  subject(:socket) { Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0) }
  let(:sockaddr) { Socket.sockaddr_in(port, "127.0.0.1") }
  let(:ignore_eaddrinuse) do
    proc do |m, *args|
      begin
        m.call(*args)
      rescue Errno::EADDRINUSE
        # ignore
      end
    end
  end

  after do
    socket.close
  end

  context "on privileged ports" do
    let(:port) { Randomized.number(1..1023) }
    stress_it "should raise Errno::EACCESS" do
      expect { socket.bind(sockaddr) }.to(raise_error(Errno::EACCES))
    end
  end

  context "on unprivileged ports" do
    let(:port) { Randomized.number(1025..65535) }
    stress_it "should bind on a port" do
      # EADDRINUSE is expected since we are picking ports at random
      # Let's ignore this specific exception
      allow(socket).to(receive(:bind).and_wrap_original(&ignore_eaddrinuse))
      expect { socket.bind(sockaddr) }.to_not(raise_error)
    end
  end

  context "on port 0" do
    let(:port) { 0 }
    stress_it "should bind successfully" do
      expect { socket.bind(sockaddr) }.to_not(raise_error)
    end
  end
end
