library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package basics_p is
    constant DEBUG: boolean := TRUE;
    function max(x : integer; y : integer) return integer;
    function clog2(x : integer) return integer;
    procedure print_dgb(msg: string);
end package basics_p;

package body basics_p is

    function max(x : integer; y : integer) return integer is
    begin
        if x >= y then
            return x;
        else 
            return y;
        end if;
    end function;

    function min(x : integer; y : integer) return integer is
    begin
        if x <= y then
            return x;
        else 
            return y;
        end if;
    end function;

    function clog2(x : integer) return integer is
    begin
        return integer(ceil(log2(real(x))));
    end function clog2;
    
    function solve_quadratic_D(a : real; b : real; c : real) return real is
        variable d: real;
    begin
        d := b**2 - real(4) * a * c;
        assert d >= real(0)
            report "D is negative!"
            severity error;
        return d;
    end function solve_quadratic_D;
    
    function solve_quadratic_pos(a : real; b : real; d : real) return real is
    begin
        return -b + sqrt(d) / real(2) / a;
    end function solve_quadratic_pos;

    function solve_quadratic_neg(a : real; b : real; d : real) return real is
    begin
        return -b - sqrt(d) / real(2) / a;
    end function solve_quadratic_neg;
    

    procedure print_dgb(msg : string) is
    begin
        if DEBUG then report msg severity note; end if;
    end procedure print_dgb;
    

end basics_p;
