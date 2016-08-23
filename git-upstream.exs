#!/usr/bin/env elixir

# A simple script of easy pushing a branch into multiple remotes.
# For example, if you have your configuration repository in 3 different
# services, and you're tired of manually pushing master to all of them.

defmodule GitDriver do
  def remotes do
    {remote_list, 0} = System.cmd("git", ["remote"])
    String.split(remote_list)
  end

  def push(remote, spec) do
    System.cmd("git", ["push", remote, spec], into: IO.stream(:stdio, 1))
  end
end

defmodule CLI do
  @usage """
  Usage: git upstream [REFSPEC] [REMOTE ...]

  REFSPEC defaults to HEAD, pushing current branch.

  If you omit list of REMOTEs, the REFSPEC will be pushed to all the remotes
  defined in the repository.
  """
  def main(["--usage" | _]) do
    IO.puts @usage
  end

  def main([parameter = <<"-", _ :: binary>> | _]) do
    IO.puts :stderr, "ERROR: unknown parameter `#{parameter}'"
    IO.puts :stderr, @usage
  end

  def main([]), do: main [ "HEAD" | GitDriver.remotes ]
  def main([spec]), do: main [ spec | GitDriver.remotes ]
  def main([spec | remotes]), do: Enum.each remotes, &(push &1, spec)

  def push(remote, spec) do
    IO.puts "*** Pushing #{spec} to #{remote} ***"
    GitDriver.push(remote, spec)
    IO.puts ""
  end
end

CLI.main System.argv
