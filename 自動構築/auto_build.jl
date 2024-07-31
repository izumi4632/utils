module AutoBuild
  # 環境変数を読み込む
  module LoadMyEnv
    using DotEnv

    # 外部から見た挙動の定義
    struct MyEnv
      OPENAI_API_KEY::String
      MODEL::String
    end
    export MyEnv

    # 実装
    function load()::Nothing
      cd(@__DIR__)
      DotEnv.load!(".env")
      nothing
    end

    make_my_env()::MyEnv = MyEnv(ENV["OPENAI_API_KEY"], ENV["MODEL"])

    # テスト
    module TestLoadMyEnv
      using Test
      using ..LoadMyEnv
  
      function test_load()
        @test_nowarn LoadMyEnv.load()
        @test        ENV["MODEL"] == "gpt-4o-mini"
      end

      function test_make_my_env_exe()
        myenv = @test_nowarn LoadMyEnv.make_my_env()
        @test        myenv.MODEL == "gpt-4o-mini"
      end

      function test()
        test_load()
        test_make_my_env_exe()
      end
    end
  end

  LoadMyEnv.TestLoadMyEnv.test()

  # プロンプトの読み出し
  module IncludePrompt

    # 実装
    function include_prompt()
      include("prompt.jl")
    end

    # テスト
    module TestIncludePrompt
      using Test
      using ..IncludePrompt

      function test_include_prompt()
        prompt = @test_nowarn IncludePrompt.include_prompt()
        @test        split(prompt, "\n")[1] == "あなたはエリート自動ソフトウェア修正チームの一員です。"
      end

      function test()
        test_include_prompt()
      end
    end
  end

  IncludePrompt.TestIncludePrompt.test()

  # 作りたいものをテキストで投げるCLI

  # AIに投げる
  
  # 特定のファイルに書き出す
  module WriteToFile
    function write_to_file(result::String, file_name::String)
      open(file_name, "w") do io
        write(io, result)
      end
    end

    # テスト
    module TestWriteToFile
      using Test
      using ..WriteToFile

      function test_write_to_file()
        @test_nowarn WriteToFile.write_to_file("test_result", "test_result.txt")
        @test        isfile("test_result.txt")
        @test        read("test_result.txt", String) == "test_result"
      end

      function test()
        test_write_to_file()
      end
    end
  end

  WriteToFile.TestWriteToFile.test()

  # 実行を行い、エラーやwarningが発生したらそれを取得する
  module Execute
    # 実装
    function execute_and_get_error(file_name::String)
      try
        result = include(file_name)
        return (result, nothing)
      catch e
        if hasproperty(e, :error) 
          if hasproperty(e.error, :msg)
            return (nothing, e.error.msg)
          else
            return (nothing, e.error)
          end
        elseif hasproperty(e, :msg)
          return (nothing, e.msg)
        else
          return (nothing, e)
        end
      end
    end

    # テスト
    module TestExecute
      using Test
      using ..Execute
      using ...WriteToFile

      function test_execute_and_get_error()
        @test_nowarn WriteToFile.write_to_file("1+3*4", "test_program.jl")
        result, error = @test_nowarn Execute.execute_and_get_error("test_program.jl")
        @test result == 13
      end

      function test_execute_and_get_error_with_error()
        @test_nowarn WriteToFile.write_to_file("1+3/*4", "test_program_with_error.jl")
        result, error = @test_nowarn Execute.execute_and_get_error("test_program_with_error.jl")
        @test (error isa String) || (error isa nothing)
        @test occursin(r"Error", error)
      end

      function test()
        test_execute_and_get_error()
        test_execute_and_get_error_with_error()
      end
    end
  end

  Execute.TestExecute.test()

  # AIに投げる
  module ThrowToAI
    using OpenAI
    # 実装

    function make_client()
      client = OpenAI.Client(api_key=ENV["OPENAI_API_KEY"])
      return client
    end

    # テスト
    module TestThrowToAI
      using Test
      using ..ThrowToAI
      using ...Execute
      using ...WriteToFile

      

      function test_throw_error()
        file_name = "test_error_throw_to_ai.jl"
        @test_nowarn WriteToFile.write_to_file("1+3/*4", file_name)
        result, error = @test_nowarn Execute.execute_and_get_error(file_name)
        if error !== nothing
          @test_nowarn ThrowToAI.throw(file_name, error)
        end
      end

      function test()
        test_throw_error()
      end
    end
  end

  ThrowError.TestThrowError.test()


  # エラーが発生する限りAIに投げて修正を適用する
  # エラーが発生しなくなったら終了する

end