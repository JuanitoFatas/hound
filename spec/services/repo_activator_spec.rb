require 'spec_helper'

describe RepoActivator do
  describe '#activate' do
    context 'when repo activation succeeds' do
      it 'activates repo' do
        token = "githubtoken"
        repo = create(:repo)
        stub_github_api
        allow(JobQueue).to receive(:push).and_return(true)

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_truthy
        expect(GithubApi).to have_received(:new).with(token)
        expect(repo.reload).to be_active
      end

      it 'makes Hound a collaborator' do
        repo = create(:repo)
        github = stub_github_api
        token = "githubtoken"
        allow(JobQueue).to receive(:push)

        RepoActivator.new(github_token: token, repo: repo).activate

        expect(github).to have_received(:add_user_to_repo)
      end

      it 'returns true if the repo activates successfully' do
        repo = create(:repo)
        stub_github_api
        token = "githubtoken"
        allow(JobQueue).to receive(:push).and_return(true)

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_truthy
      end

      context 'when https is enabled' do
        it 'creates GitHub hook using secure build URL' do
          with_https_enabled do
            repo = create(:repo)
            token = "githubtoken"
            github = stub_github_api
            allow(JobQueue).to receive(:push)

            RepoActivator.new(github_token: token, repo: repo).activate

            expect(github).to have_received(:create_hook).with(
              repo.full_github_name,
              URI.join("https://#{ENV['HOST']}", 'builds').to_s
            )
          end
        end
      end

      context 'when https is disabled' do
        it 'creates GitHub hook using insecure build URL' do
          repo = create(:repo)
          github = stub_github_api
          token = "githubtoken"
          allow(JobQueue).to receive(:push)

          RepoActivator.new(github_token: token, repo: repo).activate

          expect(github).to have_received(:create_hook).with(
            repo.full_github_name,
            URI.join("http://#{ENV['HOST']}", 'builds').to_s
          )
        end
      end
    end

    context 'when repo activation fails' do
      it 'returns false if API request raises' do
        token = nil
        repo = build_stubbed(:repo)
        allow(JobQueue).to receive(:push)
        expect(GithubApi).to receive(:new).and_raise(Octokit::Error.new)

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_falsy
      end

      it 'only swallows Octokit errors' do
        token = "githubtoken"
        repo = build_stubbed(:repo)
        allow(JobQueue).to receive(:push)
        expect(GithubApi).to receive(:new).and_raise(Exception.new)

        expect do
          RepoActivator.new(github_token: token, repo: repo).activate
        end.to raise_error(Exception)
      end

      context 'when Hound cannot be added to repo' do
        it 'returns false' do
          token = "githubtoken"
          repo = build_stubbed(:repo, full_github_name: 'test/repo')
          github = double(:github, add_user_to_repo: false)
          allow(JobQueue).to receive(:push)
          allow(GithubApi).to receive(:new).and_return(github)

          result = RepoActivator.new(github_token: token, repo: repo).activate

          expect(result).to be_falsy
        end
      end
    end

    context "when the repo has invalid attributes" do
      it "returns false when the private attribute is nil" do
        repo = build_stubbed(:repo, private: nil)
        stub_github_api
        token = "githubtoken"
        allow(JobQueue).to receive(:push)

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_falsy
      end

      it "returns false when the private attribute is nil" do
        repo = build_stubbed(:repo, in_organization: nil)
        stub_github_api
        allow(JobQueue).to receive(:push)
        token = "githubtoken"

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_falsy
      end
    end

    context "when the repo has valid attributes" do
      it "returns true when the private attribute is not nil" do
        repo = create(:repo, private: false, in_organization: false)
        stub_github_api
        allow(JobQueue).to receive(:push).and_return(true)
        token = "githubtoken"

        result = RepoActivator.new(github_token: token, repo: repo).activate

        expect(result).to be_truthy
      end
    end

    context 'hook already exists' do
      it 'does not raise' do
        token = 'token'
        repo = build_stubbed(:repo)
        allow(JobQueue).to receive(:push)
        github = double(:github, create_hook: nil, add_user_to_repo: true)
        allow(GithubApi).to receive(:new).and_return(github)

        expect do
          RepoActivator.new(github_token: token, repo: repo).activate
        end.not_to raise_error

        expect(GithubApi).to have_received(:new).with(token)
      end
    end
  end

  describe '#deactivate' do
    context 'when repo activation succeeds' do
      it 'deactivates repo' do
        stub_github_api
        token = "githubtoken"
        repo = create(:repo)
        allow(JobQueue).to receive(:push)
        create(:membership, repo: repo)

        RepoActivator.new(github_token: token, repo: repo).deactivate

        expect(GithubApi).to have_received(:new).with(token)
        expect(repo.active?).to be_falsy
      end

      it 'removes GitHub hook' do
        github_api = stub_github_api
        token = "githubtoken"
        allow(JobQueue).to receive(:push)
        repo = create(:repo)
        create(:membership, repo: repo)

        RepoActivator.new(github_token: token, repo: repo).deactivate

        expect(github_api).to have_received(:remove_hook)
        expect(repo.hook_id).to be_nil
      end

      it 'returns true if the repo activates successfully' do
        stub_github_api
        token = "githubtoken"
        allow(JobQueue).to receive(:push)
        membership = create(:membership)
        repo = membership.repo

        result = RepoActivator.new(github_token: token, repo: repo).deactivate

        expect(result).to be_truthy
      end
    end

    context 'when repo activation succeeds' do
      it 'returns false if the repo does not activate successfully' do
        repo = double('repo')
        token = nil
        allow(JobQueue).to receive(:push)
        expect(GithubApi).to receive(:new).and_raise(Octokit::Error.new)

        result = RepoActivator.new(github_token: token, repo: repo).deactivate

        expect(result).to be_falsy
      end

      it 'only swallows Octokit errors' do
        repo = double('repo')
        token = nil
        allow(JobQueue).to receive(:push)
        expect(GithubApi).to receive(:new).and_raise(Exception.new)

        expect do
          RepoActivator.new(github_token: token, repo: repo).deactivate
        end.to raise_error(Exception)
      end
    end
  end

  def stub_github_api
    hook = double(:hook, id: 1)
    api = double(:github_api, add_user_to_repo: true, remove_hook: true)
    allow(api).to receive(:create_hook).and_yield(hook)
    allow(GithubApi).to receive(:new).and_return(api)
    api
  end
end
