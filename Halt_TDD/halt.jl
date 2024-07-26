# テスト駆動開発の小ネタ 実装の詳細が分からないモックの段階でもテスト結果が確定するケース
using Test

# プログラムFは入力xに対して停止するかを判別する
function halt(F, x)::Bool
  # 実装の詳細は分からないので仮にtrueかfalseが返ってくることにする
  return [true, false][rand(1:2)]
end

# 正しいhaltを仮定した上でhaltの結果と停止性について逆の挙動を行う関数を定義する
function reverse_halt(F, x)
  result = halt(F, x)
  if result
    # 停止するという結果のとき、無限ループ（便宜的に２秒とする）して停止しない
    sleep(2)
    return result
  else
    # 停止しないとき、停止する
    return result
  end
end

# 低姿勢の結果と実行を逆転させる関数に自分自身を突っ込んだ結果をテストする
function test_reverse_halt_to_reverse_halt()
  task = @async reverse_halt(reverse_halt, "hoge")
  # 無限に近い秒数（便宜的に１秒とする）待って終わっているか確認する
  sleep(1)
  if istaskdone(task)
    @test task.result == true
  else
    @test task.result == false
  end
end

# 10回テストを行い常に失敗することを確認し
# haltの実装の詳細は分からないものの、どのように実装されても停止性問題が解決できないというRedを得る
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()
test_halt_to_halt()

#=
Test Failed at /home/izumi/git/utils/Halt_TDD/halt.jl:26
  Expression: task.result == true
   Evaluated: false == true

ERROR: There was an error during testing

or

Test Failed at /home/izumi/git/utils/Halt_TDD/halt.jl:28
  Expression: task.result == false
   Evaluated: nothing == false

ERROR: There was an error during testing
=#

# TODO: 正しいhaltの実装(Green)は示した通りこの世に存在し得ないという事になっているが、
# TODO: もしもチューリングの誤りを発見できた暁には実装する。
